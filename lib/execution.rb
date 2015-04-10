require 'open3'

# Wrapper around open3.pipeline_r which fails on error.
# and stops users from invoking the shell by accident.
#
def fail_pipe_on_error (*cmd_list, quiet: false, **opts)
  puts "Running Pipeline: \n#{debug_print_cmd_list(cmd_list)}\n" unless quiet

  cmd_list.each{ |cmd| shell_safe(cmd) }

  output, *status_list = Open3.pipeline_r(*cmd_list, opts) { |out, wait_threads|
    out_reader = Thread.new {
      if quiet
        output = out.read()
      else
        # Output from pipeline should go to stdout and also get returned for processing if necessary.
        output = tee(out, STDOUT)
      end
      out.close
      output
    }
    [out_reader.value] + wait_threads.map { |t| t.value }
  }
  exit_on_status(output, cmd_list, status_list, quiet: quiet)
end

# Wrapper around open3.popen2e which fails on error
#
# We emulate open3.capture2e with the following changes in behavior:
# 1) The command is printed to stdout before execution.
# 2) Attempts to use the shell implicitly are blocked.
# 3) Nonzero return codes result in the process exiting.
# 4) Combined stdout/stderr goes to callers stdout (continuously streamed) and is returned as a string
#
# If you're looking for more process/stream control read the spawn documentation, and pass
# options directly here
def fail_on_error (*cmd, stdin_data: nil, binmode: false, quiet: false, **opts)
  puts "Running Command: \n#{debug_print_cmd_list([cmd])}\n" unless quiet
  cmd = shell_safe(cmd)

  # Most of this is copied from Open3.capture2e in ruby/lib/open3.rb
  output, status = Open3.popen2e(*cmd, opts) { |i, oe, t|
    if binmode
      i.binmode
      oe.binmode
    end
    outerr_reader = Thread.new {
      if quiet
        oe.read
      else
        # Instead of oe.read, we redirect.
        # Output from command goes to stdout and also is returned for processing if necessary
        tee(oe, STDOUT)
      end
    }
    if stdin_data
      begin
        i.write stdin_data
      rescue Errno::EPIPE
      end
    end
    i.close
    [outerr_reader.value, t.value]
  }
  exit_on_status(output, [cmd], [status], quiet: quiet)
end

# Look at a cmd list intended for spawn.
# determine if spawn will call the shell implicitly, fail in that case.
def shell_safe (cmd)
  # Take the first string and change it to a list of [executable,argv0]
  # This syntax for calling popen2e (and eventually spawn) avoids
  # the shell in all cases
  if cmd[0].class == String
    cmd[0] = [ cmd[0], cmd[0] ]
  end
  cmd
end

def debug_print_cmd_list(cmd_list)
  # Take a list of command argument lists like you'd sent to open3.pipeline or fail_on_error_pipe and
  # print out a string that would do the same thing when entered at the shell.
  #
  # This is a converter from our internal representation of commands to a subset of bash that
  # can be executed directly.
  #
  # Note this has problems if you specify env or opts
  # TODO: make this remove those command parts
  "\"" +
    cmd_list.map { |cmd|
    cmd.map { |arg|
        arg.gsub("\"", "\\\"") # Escape all double quotes in command arguments
    }.join("\" \"") # Fully quote all command parts. We add quotes to the beginning and end too.
  }.join("\" | \"") + # Pipe commands to one another.
    "\""
end

# Takes in an input stream and an output stream
# Redirects data from one to the other until the input stream closes.
# Returns all data that passed through on return.
#
def tee(in_stream, out_stream)
  alldata = ""
  while true do
    begin
      data = in_stream.read_nonblock(4096)
      alldata += data
      out_stream.write(data)
      out_stream.flush()
    rescue IO::WaitReadable
      IO.select([in_stream])
      retry
    rescue IOError
      break
    end
  end
  alldata
end


# If any of the statuses are bad, exits with the
# return code of the first one.
#
# Otherwise returns first argument (output)
def exit_on_status (output, cmd_list, status_list, quiet: false)
  status_list.each_index do | index |
    status = status_list[index]
    cmd = cmd_list[index]
    # Do nothing for proper statuses
    if status.exited? && status.exitstatus == 0
      next
    end

    # If we exited nonzero or abnormally, print debugging info
    # and explode.
    if status.exited?
      puts "Process Exited normally. Exit status:#{status.exitstatus}" unless quiet
    else
      # This should only get executed if we're stopped or signaled
      puts "Process exited abnormally:\nProcessStatus: #{status.inspect}\nRaw POSIX Status: #{status.to_i}\n" unless quiet
    end

    raise RuntimeError, "#{status.inspect}\n#{cmd.inspect}"
  end

  # This is some output of the command which ideally we're not interested in
  # for the failure case
  output
end
