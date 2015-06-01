# Copyright 2015 Square Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Gem::Specification.new do |s|
  s.name        = 'build_execution'
  s.version     = '0.1.1'
  s.date        = '2015-04-10'
  s.summary     = "Execution for Build and release scripts"
  s.description = "Run commands without invoking the shell, and force handling of error exit within scripts"
  s.authors     = ["Michael Tauraso"]
  s.email       = 'mtauraso@gmail.com'
  s.files       = ["lib/build_execution.rb"]
  s.homepage    =
    'http://rubygems.org/gems/build_execution'
  s.license       = 'Apache'
end
