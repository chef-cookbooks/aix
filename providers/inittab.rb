#
# Copyright:: 2014-2016, Chef Software, Inc.
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

use_inline_resources

# Support whyrun
def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::AixInittab.new(@new_resource.name)
  @current_resource.exists = false

  so = shell_out("lsitab #{@new_resource.identifier}")
  unless so.error?
    @current_resource.exists = true
    fields = so.stdout.lines.first.chomp.split(':')
    # perfstat:2:once:/usr/lib/perf/libperfstat_updt_dictionary >/dev/console 2>&1
    @current_resource.identifier(fields[0])
    @current_resource.runlevel(fields[1])
    @current_resource.processaction(fields[2])
    @current_resource.command(fields[3])
  end
end

action :install do
  if !@current_resource.exists || (@current_resource.runlevel != @new_resource.runlevel || @current_resource.processaction != @new_resource.processaction || @current_resource.command != @new_resource.command)

    converge_by('Install or update inittab') do
      if @current_resource.exists
        shell_out("rmitab #{@current_resource.identifier}")
      end
      follow = "-i #{@new_resource.follows} " if @new_resource.follows
      shell_out("mkitab #{follow}\"#{[@new_resource.identifier, @new_resource.runlevel, @new_resource.processaction, @new_resource.command].join(':')}\"")
    end
  end
end

action :remove do
  if @current_resource.exists
    converge_by('Remove inittab entry') do
      shell_out("rmitab #{@current_resource.identifier}")
    end
  end
end
