#
# Copyright 2015-2016, Benoit Creau <benoit.creau@chmod666.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/mixin/shell_out'

include Chef::Mixin::ShellOut

use_inline_resources

# support whyrun
def whyrun_supported?
  true
end

# loading current resource
def load_current_resource
  @current_resource = Chef::Resource::AixFixes.new(@new_resource.name)

  emgr = Mixlib::ShellOut.new('emgr -l')
  emgr.run_command
  emgr.error!
  Chef::Log.fatal('emgr: error while running emgr') unless emgr.exitstatus

  # resource does not exists if there are no efix installed on the system
  if emgr.stdout == 'There is no efix data on this system'
    @current_resource.exists = false
  else
    @current_resource.exists = true
    array_fixes = []
    emgr.stdout.each_line do |line|
      line_array = line.split(' ')
      if line_array[0] =~ /[0-9]/
        Chef::Log.debug("emgr: adding fixe #{line_array[0]} to fixes list")
        array_fixes.push(line_array[2])
      end
    end
    @current_resource.fixes(array_fixes)
  end
end

action :remove do
  if @current_resource.exists
    if @new_resource.fixes[0] == 'all'
      @current_resource.fixes.each do |fix|
        converge_by("emgr: removing fix #{fix}") do
          remove_emgr = Mixlib::ShellOut.new("emgr -r -L #{fix}")
          remove_emgr.run_command
          remove_emgr.error!
          unless remove_emgr.exitstatus
            Chef::Log.fatal("emgr: error while trying to removing fix #{fix}")
          end
        end
      end
    else
      @new_resource.fixes.each do |fix|
        converge = false
        @current_resource.fixes.each do |i_fix|
          converge = true if i_fix.include? fix
          next unless converge
          converge_by("emgr: removing fix #{fix}") do
            remove_emgr = Mixlib::ShellOut.new("emgr -r -L #{fix}")
            remove_emgr.run_command
            remove_emgr.error!
            unless remove_emgr.exitstatus
              Chef::Log.fatal("emgr: error while trying to removing fix #{fix}")
            end
          end
        end
      end
    end
  end
end

action :install do
  fix_directory = @new_resource.directory
  @new_resource.fixes.each do |fix|
    emgr_install_string = 'emgr -X -e ' << fix_directory << '/' << fix
    converge = true
    if @current_resource.exists
      @current_resource.fixes.each do |i_fix|
        converge = false if fix.include? i_fix
      end
    end
    next unless converge
    converge_by("emgr: installing fix #{fix}") do
      install_emgr = Mixlib::ShellOut.new(emgr_install_string)
      install_emgr.run_command
      install_emgr.error!
      unless install_emgr.exitstatus
        Chef::Log.fatal("emgr: error while trying to install fix #{fix}")
      end
    end
  end
end
