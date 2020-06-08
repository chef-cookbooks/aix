#
# Copyright:: 2016, Alain Dejoux <adejoux@djouxtech.net>
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

include WPARHelper

property :wpar_name, String, name_property: true
property :hostname, String
property :address, String
property :interface, String
property :rootvg, [true, false], default: false
property :rootvg_disk, String
property :wparvg, String
property :backupimage, String
property :cpu, String
property :memory, String
property :autostart, [true, false], default: false
property :wpar_state, String
property :live_stream, [true, false], default: false

# loading current resource
load_current_value do |new_resource|
  require_wpar_gem

  # Get current WPAR on the system
  wpar = ::WPAR::WPARS.new[new_resource.wpar_name]
  current_value_does_not_exist! if wpar.nil?

  wpar.live_stream = STDOUT if new_resource.live_stream
  current_resource.wpar_state = wpar.general.state
  current_resource.cpu = wpar.resource_control.cpu
  unless wpar.networks.first.nil?
    address wpar.networks.first.address
    interface wpar.networks.first.interface
  end

  autostart true if wpar.general.auto == 'yes'
  rootvg true if wpar.general.rootvgwpar == 'yes'
  # get the hdisk used if it's a rootvg wpar
  unless wpar.get_rootvg.empty?
    rootvg true
    rootvg_disk wpar.devices.get_rootvg.first.devname
  end
end

# create action
action :create do
  options = {}
  Chef::Log.debug("wpar #{current_resource.wpar_state} ")
  if current_resource
    Chef::Log.info("wpar #{new_resource.wpar_name} already exist")
  else
    require_wpar_gem
    wpar = WPAR::WPAR.new(name: new_resource.wpar_name)
    wpar.general.auto = new_resource.autostart || 'no'
    wpar.live_stream = STDOUT if new_resource.live_stream
    options[:rootvg] = new_resource.rootvg_disk if new_resource.rootvg

    options[:backupimage] = new_resource.backupimage if new_resource.backupimage

    options[:wparvg] = new_resource.wparvg if new_resource.wparvg

    wpar.resource_control.cpu = new_resource.cpu if new_resource.cpu
    wpar.general.hostname = new_resource.hostname
    # create a network if specified
    if new_resource.address
      wpar.networks.add(name: new_resource.wpar_name,
                        address: new_resource.address,
                        interface: new_resource.interface)
    end

    converge_by('creating wpar') do
      wpar.create(options)
    end
  end
end

# start action
action :start do
  if current_resource && current_resource.wpar_state == 'D'
    converge_by("Start wpar #{current_resource.wpar_name}") do
      wpar = ::WPAR::WPARS.new[current_resource.wpar_name]
      wpar.start if wpar
    end
  else
    Chef::Log.error("wpar #{new_resource.wpar_name} not in correct state")
  end
end

# stop action
action :stop do
  if current_resource && current_resource.wpar_state == 'A'
    converge_by("Stop wpar #{current_resource.wpar_name}") do
      wpar = ::WPAR::WPARS.new[current_resource.wpar_name]
      wpar.stop if wpar
    end
  else
    Chef::Log.error("wpar #{new_resource.wpar_name} not in correct state")
  end
end

# action delete
action :delete do
  if current_resource
    converge_by("Delete wpar #{current_resource.wpar_name}") do
      wpar = ::WPAR::WPARS.new[current_resource.wpar_name]
      wpar.destroy(force: true) if wpar
    end
  else
    Chef::Log.error("wpar #{new_resource.wpar_name} doesn't exist")
  end
end

# action sync
action :sync do
  if current_resource
    converge_by("Sync wpar #{current_resource.wpar_name}") do
      wpar = ::WPAR::WPARS.new[current_resource.wpar_name]
      wpar.sync if wpar
    end
  else
    Chef::Log.error("wpar #{new_resource.wpar_name} doesn't exist")
  end
end
