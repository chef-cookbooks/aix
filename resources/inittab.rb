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

property :identifier, String, name_property: true
property :runlevel, String, required: true
property :processaction, String, required: true, equal_to: %w(respawn wait once boot bootwait powerfail off hold ondemand initdefault sysinit)
property :command, String, required: true

property :follows, String
property :exists, [true, false], desired_state: false

load_current_value do |new_resource|
  exists false
  so = shell_out("lsitab #{new_resource.identifier}")
  if so.error?
    current_value_does_not_exist!
  else
    exists true
    fields = so.stdout.lines.first.chomp.split(':')
    # perfstat:2:once:/usr/lib/perf/libperfstat_updt_dictionary >/dev/console 2>&1
    identifier(fields[0])
    runlevel(fields[1])
    processaction(fields[2])
    command(fields[3])
  end
end

action :install do
  converge_if_changed(:runlevel, :processaction, :command) do
    converge_by('Install or update inittab') do
      unless current_value.nil?
        shell_out("rmitab #{current_value.identifier}")
      end
      follow = "-i #{new_resource.follows} " if new_resource.follows
      shell_out("mkitab #{follow}\"#{[new_resource.identifier, new_resource.runlevel, new_resource.processaction, new_resource.command].join(':')}\"")
    end
  end
end

action :remove do
  unless current_value.nil?
    converge_by('Remove inittab entry') do
      shell_out("rmitab #{current_value.identifier}")
    end
  end
end
