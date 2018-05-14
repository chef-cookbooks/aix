#
# Copyright:: 2015-2017, Benoit Creau <benoit.creau@chmod666.org>
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

use_inline_resources # ~FC113

# support whyrun
def whyrun_supported?
  true
end

# loading current resource
def load_current_resource
  @current_resource = new_resource.class.new(@new_resource.name)

  emgr = shell_out('/usr/sbin/emgr -l')
  Chef::Log.fatal('emgr: error while running emgr') if emgr.error?
  emgr.error!

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
    fixes_to_remove = if @new_resource.fixes[0].downcase == 'all'
                        @current_resource.fixes
                      else
                        @new_resource.fixes
                      end
    Chef::Log.info("efixes requested to be removed: #{fixes_to_remove}")
    fixes_to_remove.each do |fix|
      converge = false
      unless @new_resource.fixes[0].downcase == 'all'
        @current_resource.fixes.each do |i_fix|
          converge = true if i_fix.include? fix
        end
        unless converge
          Chef::Log.error("efix: #{fix} is not installed.")
          next
        end
      end
      converge_by("emgr: fix #{fix} removed.\n") do
        Chef::Log.debug("emgr: removing efix #{fix} using command: /usr/sbin/emgr -r -L #{fix}")
        remove_emgr = shell_out("/usr/sbin/emgr -r -L #{fix}")
        if remove_emgr.error?
          Chef::Log.fatal("emgr: error while trying to removing fix #{fix}")
          Chef::Log.error(remove_emgr.stdout)
          remove_emgr.error!
        end
      end
    end
  end
end

action :install do
  fix_directory = @new_resource.directory
  if Dir.exist?(fix_directory)
    Dir.chdir(fix_directory)
    packages = if @new_resource.fixes[0].downcase == 'all'
                 Dir.glob('*.epkg.Z')
               else
                 @new_resource.fixes
               end
    packages.sort! { |x, y| y <=> x }

    packages.each do |fix|
      emgr_install_string = '/usr/sbin/emgr -p -e ' << fix_directory << '/' << fix
      Chef::Log.debug("emgr: installing in preview mode efix #{fix} using command: #{emgr_install_string}")
      install_emgr = shell_out(emgr_install_string)
      if install_emgr.error?
        Chef::Log.error("emgr: error during preview install, fix package: #{fix} skiped.")
        Chef::Log.info(install_emgr.stdout)
        next
      end

      emgr_install_string = '/usr/sbin/emgr -X -e ' << fix_directory << '/' << fix
      converge_by("emgr: fix #{fix} installed.\n") do
        Chef::Log.debug("emgr: installing efix #{fix} using command: #{emgr_install_string}")
        install_emgr = shell_out(emgr_install_string)
        if install_emgr.error?
          Chef::Log.fatal("emgr: error while trying to install fix #{fix}")
          Chef::Log.error(install_emgr.stdout)
          install_emgr.error!
        end
      end
    end
  else
    Chef::Log.fatal("dir: #{fix_directory} does not exist")
  end
end
