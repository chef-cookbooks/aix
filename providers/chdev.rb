#
# Author:: Vianney Foucault (<vianney.foucault@gmail.com>)
# Cookbook Name:: aix
# Provider:: chdev
#
# Copyright:: 2015, The Author
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

action :update do
  if not @current_resource.exists
    Chef::Log.info "Cannot modify device #{@current_resource.name} - does not exist."
    raise "Cannot modify device #{@current_resource.name} - does not exist."
  else
    attributes = Hash.new
    @new_resource.attributes.each do |attrname,value|
      if not @current_resource.attributes[attrname] == value
        attributes[attrname.to_s] = @new_resource.attributes[attrname]
      end
    end
    if attributes.length != 0
      cmd = "chdev -l #{@current_resource.name} "
      attributes.each do |k,v|
        cmd << "-a #{k}=#{v}" if not v.nil?
      end

      if @new_resource.atreboot
        cmd << " -P "
      end
      converge_by("Updating device #{@current_resource.name}") do
        cmd = Mixlib::ShellOut.new(cmd)
        cmd.valid_exit_codes = 0
        cmd.run_command
        cmd.error!
        cmd.error?
      end
    end
  end
end
def load_current_resource
  @current_resource = Chef::Resource::AixChdev.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.exists = false
  if device_exists?(@current_resource.name)
    @current_resource.exists = true
    load_device_attributes
  end
end

def load_device_attributes
  cmd = Mixlib::ShellOut.new("lsattr -E -O -l #{@current_resource.name}")
  cmd.run_command
  cmd.stdout.chomp!
  attr_name = cmd.stdout.lines.first.split(':').map(&:strip).map(&:to_sym)
  attr_value = cmd.stdout.lines.last.split(':').map { |x| if x == "true" ; true ; elsif x == "false" ; false ; elsif x.to_i.to_s === x; x.to_i; else;  x ; end }
  attrs = Hash[attr_name.zip(attr_value)]
  @current_resource.attributes(attrs)
end

def device_exists?(name)
  cmd = Mixlib::ShellOut.new("lsattr -El #{@current_resource.name}")
  cmd.valid_exit_codes = 0
  cmd.run_command
  !cmd.error?
end
