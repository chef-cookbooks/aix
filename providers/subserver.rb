#
# Author:: Julian Dunn (<jdunn@chef.io>)
# Cookbook Name:: aix
# Provider:: subserver
#
# Copyright:: 2014, Chef Software, Inc.
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

# Support whyrun
def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::AixSubserver.new(@new_resource.name)
  @current_resource.enabled = false

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
      next unless @new_resource.servicename == line_array[0] && @new_resource.protocol == line_array[2]
      @current_resource.enabled = service_enabled
      @current_resource.servicename(line_array[0])
      @current_resource.type(line_array[1])
      @current_resource.protocol(line_array[2])
      @current_resource.wait(line_array[3])
      @current_resource.user(line_array[4])
      @current_resource.program(line_array[5])
      @current_resource.args = line_array.slice(6, line_array_length - 5).join(' ')
    end
  ensure
    inetd.close unless inetd.nil?
  end
end

action :enable do
  if @current_resource.enabled
    if @current_resource.type != @new_resource.type ||
       @current_resource.wait != @new_resource.wait ||
       @current_resource.user != @new_resource.user ||
       @current_resource.program != @new_resource.program ||
       @current_resource.args != @new_resource.args
      cmd = "chsubserver -c -v #{@current_resource.servicename} -p #{@current_resource.protocol}"
      cmd << " -T #{@new_resource.type}" if @current_resource.type != @new_resource.type
      cmd << " -W #{@new_resource.wait}" if @current_resource.wait != @new_resource.wait
      cmd << " -U #{@new_resource.user}" if @current_resource.user != @new_resource.user
      cmd << " -G #{@new_resource.program}" if @current_resource.program !- @new_resource.program
      cmd << " -P #{@new_resource.protocol}" if @current_resource.protocol != @new_resource.protocol
      # Note, you can't change args using chsubserver, probably because args can contain spaces
      converge_by('change subserver entry') do
        shell_out(cmd)
      end
    end
  else
    cmd = "chsubserver -a -v #{@new_resource.servicename} -p #{@new_resource.protocol}"
    cmd << " -t #{@new_resource.type}" if @new_resource.type
    cmd << " -w #{@new_resource.wait}" if @new_resource.wait
    cmd << " -u #{@new_resource.user}" if @new_resource.user
    cmd << " -g #{@new_resource.program}"
    cmd << " #{@new_resource.program} #{@new_resource.args}"
    converge_by('enable subserver') do
      shell_out(cmd)
    end
  end
end

action :disable do
  if @current_resource.enabled
    converge_by('disable subserver') do
      shell_out("chsubserver -d -v #{@current_resource.servicename} -p #{@current_resource.protocol}")
    end
  end
end
