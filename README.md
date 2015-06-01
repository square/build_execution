# build_execution gem
Execution primitives that force explicit error handling and never call the shell.

## How to use
The interface is similar to Open3.capture2e. We print the command to stdout before running it (unless `:quiet=> true`). By default the command process shares the calling process's stdout, but this can be changed. Options passed to fail_on_error are passed through to popen2e.

```
> require 'build_execution'
> fail_on_error('/bin/echo', '-n', 'asdf')
Running Command:
"/bin/echo" "-n" "asdf"
asdf => "asdf"
> fail_on_error('/bin/echo', '-n', 'asdf', :quiet=>true)
 => "asdf"
 >
 ```

`fail_pipe_on_error` has a similar interface, but it takes lists of commands similar to Open3.pipeline. Any additional options are passed to Open3.pipeline_r under the hood.


