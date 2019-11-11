#
# Copyright:: 2014-2019, Chef Software, Inc.
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

property :servicename, String, name_property: true, identity: true
property :type, String, equal_to: %w(dgram stream sunrpc_udp sunrpc_tcp)
property :protocol, String, required: true, equal_to: %w(tcp udp tcp6 udp6), desired_state: false
property :wait, String, equal_to: %w(wait nowait SRC), default: 'nowait'
property :user, String, required: true, default: 'root'
property :program, String
property :args, String
property :enabled, [true, false]
property :running, [true, false]

load_current_value do |desired|
  valid_protocols = %w(tcp udp tcp6 udp6)
  begin
    inetd = ::File.open('/etc/inetd.conf')
    inetd.each_line do |line|
      next if line =~ /^##/ # standard IBM comment
      line_array = line.split(' ')
      line_array_length = line_array.length
      next unless line_array_length > 1 && valid_protocols.include?(line_array[2])
      if line_array[0].chars[0] == '#'
        line_array[0] = line_array[0].sub(/^#/, '')
        service_enabled = false
      else
        service_enabled = true
      end
      # next unless current_resource.servicename == line_array[0] && current_resource.protocol == line_array[2]
      next unless desired.servicename == line_array[0] && desired.protocol == line_array[2]
      enabled service_enabled
      servicename line_array[0]
      type line_array[1]
      protocol line_array[2]
      wait line_array[3]
      user line_array[4]
      program line_array[5]
      args line_array.slice(6, line_array_length - 5).join(' ')
    end
  ensure
    inetd.close unless inetd.nil?
  end
end

action :enable do
  if current_resource.enabled
    if current_resource.type != new_resource.type ||
       current_resource.wait != new_resource.wait ||
       current_resource.user != new_resource.user ||
       current_resource.program != new_resource.program ||
       current_resource.args != new_resource.args
      cmd = "chsubserver -c -v #{current_resource.servicename} -p #{current_resource.protocol}"
      cmd << " -T #{new_resource.type}" if current_resource.type != new_resource.type
      cmd << " -W #{new_resource.wait}" if current_resource.wait != new_resource.wait
      cmd << " -U #{new_resource.user}" if current_resource.user != new_resource.user
      cmd << " -G #{new_resource.program}" if current_resource.program !- new_resource.program
      cmd << " -P #{new_resource.protocol}" if current_resource.protocol != new_resource.protocol
      # Note, you can't change args using chsubserver, probably because args can contain spaces
      converge_by('change subserver entry') do
        shell_out(cmd)
      end
    end
  else
    cmd = "chsubserver -a -v #{new_resource.servicename} -p #{new_resource.protocol}"
    cmd << " -t #{new_resource.type}" if new_resource.type
    cmd << " -w #{new_resource.wait}" if new_resource.wait
    cmd << " -u #{new_resource.user}" if new_resource.user
    cmd << " -g #{new_resource.program}"
    cmd << " #{new_resource.program} #{new_resource.args}"
    converge_by('enable subserver') do
      shell_out(cmd)
    end
  end
end

action :disable do
  if current_resource.enabled
    converge_by('disable subserver') do
      shell_out("chsubserver -d -v #{current_resource.servicename} -p #{current_resource.protocol}")
    end
  end
end
