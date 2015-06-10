#
# Author:: Julian Dunn (<jdunn@chef.io>)
# Author:: Vianney Foucault (<vianney.foucault@gmail.com>)
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

# Support whyrun
def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::AixSubserver.new(@new_resource.name)
  ## init attr_accessor with right values
  @current_resource.enabled = false
  @current_resource.exists = false
  @current_resource.already_exists_with_new_name = false
  begin
    inetd = ::File.open('/etc/inetd.conf')
    ## we will look for a string that
    ## => can or not start with a hash
    ## => is next composed of the current service name OR the new service name
    ## => followed next by 9 multiple space OR a suite of letters (type/protocol/wait/user)
    ## => followed by one suite of any non white space chars (command)
    ## => followed by a multiple suite of space OR non whitespace chars at least 0 times (args)
    ## => followed by the end of the line
    line = inetd.grep(/^(#){0,1}(#{@current_resource.servicename}|#{@new_resource.servicename})((\s+|\w+){9})((\s+|\w+){9})((\S+)(\s+|\S+){0,}$)/)
    if line.length != 0
      ## if line is larger than 0, it means that we've found something
      subserver = line[0].split(/\s+/)
      ## if the servicename extracted from the file equals the new service name and not the current one, it means that our service is already renamed
      if subserver[0].gsub(/^#/,'') == @new_resource.servicename && @new_resource.servicename != @current_resource.servicename
        @current_resource.already_exists_with_new_name = true
        Chef::Log.warn "resource already renamed or exists with another name"
      else
        @current_resource.exists = true
        @current_resource.enabled = (subserver[0][0] != "#")
        @current_resource.type(subserver[1])
        @current_resource.protocol(subserver[2])
        @current_resource.wait(subserver[3])
        @current_resource.user(subserver[4])
        @current_resource.program(subserver[5])
        @current_resource.args(subserver[6,subserver.length].join(' '))
      end
    else
      Chef::Log.info "subserver #{@current_resource.servicename} does not exists."
    end
  ensure
    inetd.close unless inetd.nil?
  end
end

def check_basic_settings()
  if @new_resource.type and @new_resource.type == "stream"
    if @new_resource.wait and not @new_resource.wait == "nowait" or not @current_resource.wait == "nowait"
      Chef::Log.error "A Stream socket can only be set to \"nowait\""
      raise "A Stream socket can only be set to \"nowait\""
    end
  end
  if @new_resource.type and @new_resource.type =~ /udp/
    if @new_resource.protocol and not @new_resource.protocol =~ /udp/ or not @current_resource.protocol =~ /udp/
      Chef::Log.error "A sunrpc_udp socket can only be set to a udp protocol"
      raise "A sunrpc_udp socket can only be set to a udp protocol"
    end
  end
  if @new_resource.type and @new_resource.type =~ /tcp/
    if @new_resource.protocol and not @new_resource.protocol =~ /tcp/ or not @current_resource.protocol =~ /tcp/
      Chef::Log.error "A sunrpc_tcp socket can only be set to a tcp protocol"
      raise "A sunrpc_tcp socket can only be set to a tcp protocol"
    end
  end
  return true
end


def check_basic_settings()
  if @new_resource.type and @new_resource.type == "stream"
    if @new_resource.wait and @new_resource.wait != "nowait" or @current_resource.wait != "nowait"
      Chef::Log.error "A Stream socket can only be set to \"nowait\""
      raise "A Stream socket can only be set to \"nowait\""
    end
  end
  if @new_resource.type and @new_resource.type =~ /udp/
    if @new_resource.protocol and not @new_resource.protocol =~ /udp/ or not @current_resource.protocol =~ /udp/
      Chef::Log.error "A sunrpc_udp socket can only be set to a udp protocol"
      raise "A sunrpc_udp socket can only be set to a udp protocol"
    end
  end
  if @new_resource.type and @new_resource.type =~ /tcp/
    if @new_resource.protocol and not @new_resource.protocol =~ /tcp/ or not @current_resource.protocol =~ /tcp/
      Chef::Log.error "A sunrpc_tcp socket can only be set to a tcp protocol"
      raise "A sunrpc_tcp socket can only be set to a tcp protocol"
    end
  end
  return true
end


action :enable do
  if not @current_resource.exists and not @current_resource.already_exists_with_new_name
    if  @new_resource.type.nil? || @new_resource.protocol.nil? || @new_resource.wait.nil? || @new_resource.user.nil? || @new_resource.program.nil?
      Chef::Log.error "Not enough settings provided to create the subserver"
      raise "Not enough settings provided to create the subserver"
    elsif check_basic_settings
      cmd = "chsubserver -a -v #{@new_resource.servicename} -p #{@new_resource.protocol}"
      cmd << " -t #{@new_resource.type}"
      cmd << " -p #{@new_resource.protocol}"
      cmd << " -w #{@new_resource.wait}"
      cmd << " -u #{@new_resource.user}"
      cmd << " -g #{@new_resource.program}"
      cmd << " #{@new_resource.args}" if @new_resource.args
      converge_by("Creating subserver #{@new_resource.servicename}") do
        shell_out(cmd)
      end
    end
  elsif @current_resource.exists and @new_resource.type || @new_resource.wait || @new_resource.user || @new_resource.program || @new_resource.protocol || @new_resource.args ||  @new_resource.servicename and check_basic_settings
    if @current_resource.type != @new_resource.type or @current_resource.servicename != @new_resource.servicename or @current_resource.wait != @new_resource.wait or @current_resource.user != @new_resource.user or @current_resource.program != @new_resource.program or @current_resource.protocol != @new_resource.protocol or @current_resource.args != @new_resource.args
      cmd = "chsubserver -c -v #{@current_resource.servicename} -p #{@current_resource.protocol}"
      cmd << " -T #{@new_resource.type}" if @current_resource.type != @new_resource.type
      cmd << " -V #{@new_resource.servicename}" if @current_resource.servicename != @new_resource.servicename
      cmd << " -W #{@new_resource.wait}" if @current_resource.wait != @new_resource.wait
      cmd << " -U #{@new_resource.user}" if @current_resource.user != @new_resource.user
      cmd << " -G #{@new_resource.program}" if @current_resource.program != @new_resource.program
      cmd << " -P #{@new_resource.protocol}" if @current_resource.protocol != @new_resource.protocol
      cmd << " #{@new_resource.args}" if @current_resource.args != @new_resource.args
      converge_by("Update subserver #{@new_resource.servicename}") do
        shell_out(cmd)
      end
    end
  else
    cmd = "chsubserver -a -v #{@new_resource.servicename} -p #{@new_resource.protocol}"
    converge_by("Enable subserver #{@new_resource.servicename}") do
      puts cmd
      shell_out(cmd)
    end
  end
end

action :disable do
  if @current_resource.enabled
    converge_by("disable subserver #{@current_resource.servicename}") do
      shell_out("chsubserver -d -v #{@current_resource.servicename} -p #{@current_resource.protocol} -r #{@new_resource.servicename}")
    end
  end
end

