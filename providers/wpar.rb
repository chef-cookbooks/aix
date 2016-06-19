#
# Author:: Alain Dejoux (<adejoux@djouxtech.net>)
# Cookbook Name:: aix
# Provider:: wpar
#
# Copyright:: 2016, Alain Dejoux
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
require 'chef/mixin/shell_out'
require 'wpars'

include Chef::Mixin::ShellOut

use_inline_resources

# support whyrun
def whyrun_supported?
  true
end

# loading current resource
def load_current_resource
  @current_resource = Chef::Resource::AixWpar.new(@new_resource.name)

  # get all WPAR on the system
  wpars = WPAR::WPARS.new

  #get the current wpar
  @wpar = wpars[@new_resource.name]
  if @wpar.nil?
    @current_resource.exists=false
  else
    @current_resource.exists=true
  end

  if @current_resource.exists
    if @new_resource.live_stream
      @wpar.live_stream = STDOUT
    end
    @current_resource.state =  @wpar.general.state
    @current_resource.cpu = @wpar.resource_control.cpu
    unless @wpar.networks.first.nil?
      @current_resource.address = @wpar.networks.first.address
      @current_resource.interface = @wpar.networks.first.interface
    end

    if @wpar.general.auto == "yes"
      @current_resource.autostart = true
    end
    if @wpar.general.rootvgwpar == "yes"
      @current_resource.rootvg = true
    end
    #get the hdisk used if it's a rootvg wpar
    unless @wpar.get_rootvg.empty?
      @current_resource.rootvg = true
      @current_resource.rootvg_disk=@wpar.devices.get_rootvg.first.devname
    end
  end

  Chef::Log.debug(@current_resource)
end

#create action
action :create do
  options = {}
  Chef::Log.debug("wpar #{@current_resource.state} ")
  if @current_resource.exists
    Chef::Log.info("wpar #{@new_resource.name} already exist")
  else
    wpar = WPAR::WPAR.new(name: @new_resource.name)
    wpar.general.auto = @new_resource.autostart || "no"
    if @new_resource.live_stream
      wpar.live_stream = STDOUT
    end
    if @new_resource.rootvg
      options[:rootvg]=@new_resource.rootvg_disk
    end

    if @new_resource.backupimage
      options[:backupimage]=@new_resource.backupimage
    end

    if @new_resource.wparvg
      options[:wparvg]=@new_resource.wparvg
    end

    if @new_resource.cpu
      wpar.resource_control.cpu = @new_resource.cpu
    end
    wpar.general.hostname = @new_resource.hostname
    #create a network if specified
    if @new_resource.address
      wpar.networks.add(name: @new_resource.name,
                        address: @new_resource.address,
                        interface: @new_resource.interface)
    end

    converge_by("creating wpar") do
      wpar.create(options)
    end
  end
end

#start action
action :start do
  if @current_resource.exists && @current_resource.state == "D"
    converge_by("Start wpar #{@current_resource.name}") do
      @wpar.start
    end
  else
    Chef::Log.error("wpar #{@new_resource.name} not in correct state")
  end
end

#stop action
action :stop do
  if @current_resource.exists && @current_resource.state == "A"
    converge_by("Stop wpar #{@current_resource.name}") do
      @wpar.stop
    end
  else
    Chef::Log.error("wpar #{@new_resource.name} not in correct state")
  end
end

#action delete
action :delete do
  if @current_resource.exists
    converge_by("Delete wpar #{@current_resource.name}") do
      @wpar.destroy(force: true)
    end
  else
    Chef::Log.error("wpar #{@new_resource.name} doesn't exist")
  end
end

#action sync
action :sync do
  if @current_resource.exists
    converge_by("Sync wpar #{@current_resource.name}") do
      @wpar.sync()
    end
  else
    Chef::Log.error("wpar #{@new_resource.name} doesn't exist")
  end
end
