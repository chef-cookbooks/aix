#
# Author:: Benoit Creau (<benoit.creau@chmod666.org>)
# Cookbook Name:: aix
# Provider::  alt_disk
#
# Copyright:: 2015, Benoit Creau
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

include Chef::Mixin::ShellOut

use_inline_resources

# support whyrun
def whyrun_supported?
  true
end

# loading current resource
def load_current_resource
  @current_resource = Chef::Resource::AixAltdisk.new(@new_resource.name)
  @current_resource.exists=false

  # if there is no altdisk_name specified in the recipe the altdisk_name will be the default one
  # (altinst_rootvg)
  unless @new_resource.altdisk_name.nil?
    altdisk_name=@new_resource.altdisk_name
  else 
    altdisk_name="altinst_rootvg"
    @new_resource.altdisk_name("altinst_rootvg")
  end

  lspv_altinst_rootvg=Mixlib::ShellOut.new("lspv | awk '$3 == \"#{altdisk_name}\" {print $1}")
  lspv_altinst_rootvg.run_command
  lspv_altinst_rootvg.error!
  if !lspv_altinst_rootvg.exitstatus
    Chef::Log.fatal("altdisk: can't run lspv")
  end

  # these attribute are useful if we are working on an existing rootvg, so an altdisk exists
  if lspv_altinst_rootvg.stdout.empty?
    Chef::Log.debug("altdisk: can't find any disk named #{altdisk_name}")
  else
    @current_resource.type(:name)
    @current_resource.value(lspv_altinst_rootvg.stdout)
    @current_resource.exists = true
  end
  
end

# action create 
# Create an alternate disk
action :create do
  # we are creating an alternate disk only if there are no current alternate disk
  if !@current_resource.exists
    Chef::Log.info("alt_disk: action create")
    type=@new_resource.type
    value=@new_resource.value
    # searching for the disk on which create the alternate disk
    Chef::Log.debug("type : #{type}, value : #{value}")
    disk=find_and_check_disk(type,value)
    if disk != "None"
      Chef::Log.debug("alt_disk: we found a disk #{disk}")
      converge_by("alt_disk: creating alternate rootvg disk name #{@new_resource.altdisk_name} on disk #{disk}") do
        alt_disk_copy_str="alt_disk_copy -d #{disk}" 
        if !@new_resource.change_bootlist
          alt_disk_copy_str=alt_disk_copy_str << " -B "
        end
        if @new_resource.reset_devices
          alt_disk_copy_str=alt_disk_copy_str << " -O "
        end
        if @new_resource.remain_nimclient
          alt_disk_copy_str=alt_disk_copy_str << " -n "
        end
        Chef::Log.debug("alt_disk: running command #{alt_disk_copy_str}")
        alt_disk_copy=Mixlib::ShellOut.new(alt_disk_copy_str, :timeout => 7200)
        alt_disk_copy.run_command
        alt_disk_copy.error!
        if !alt_disk_copy.exitstatus
          Chef::Log.fatal("alt_disk: can't create alternate disk")
        end
        #renaming if needed
        if @new_resource.altdisk_name != "altinst_rootvg"
          alt_rootvg_op_str="alt_rootvg_op -v #{@new_resource.altdisk_name} -d #{disk}"
          alt_rootvg_op=Mixlib::ShellOut.new(alt_rootvg_op_str)
          alt_rootvg_op.run_command
          alt_rootvg_op.error!
          if !alt_rootvg_op.exitstatus
            Chef::Log.fatal("alt_disk: can't rename alternate disk")
          end
        end
      end
    else
      Chef::Log.debug("alt_disk: no suitable disk found for alternate disk copy")
    end 
  end
end

# action cleanup
# Cleanup an alternate disk
action :cleanup do
  Chef::Log.debug("alt_disk: action cleanup")
  if @current_resource.exists
    converge_by("alt_disk: cleanup alternate rootvg #{@new_resource.altdisk_name}") do
      alt_rootvg_op_str="alt_rootvg_op -X"
      if @new_resource.altdisk_name != "altinst_rootvg"
        alt_rootvg_op_str=alt_rootvg_op_str << " #{@new_resource.altdisk_name}"
      end
      alt_rootvg_op=Mixlib::ShellOut.new(alt_rootvg_op_str)
      alt_rootvg_op.run_command
      alt_rootvg_op.error!
      if !alt_rootvg_op.exitstatus
        Chef::Log.fatal("alt_disk: can't cleanup alternate rootvg")
      end
    end
  end
end

# action rename
# Rename an alternate disk
action :rename do
  Chef::Log.debug("alt_disk: action rename")
  if @current_resource.exists
    alt_rootvg_op_str="alt_rootvg_op -v #{@new_resource.new_altdisk_name}"	
    if @current_resource.altdisk_name != "altinst_rootvg"
      disk="None"
      lspv_altdisk=shell_out("lspv | awk '$3 == \"#{@new_resource.altdisk_name}\"'")
      lspv_altdisk.stdout.each_line do |a_pv|
        current_pv_a=a_pv.split(" ")
        if current_pv_a[2] == @new_resource.altdisk_name
          disk=current_pv_a[0]
        end
      end
      alt_rootvg_op_str=alt_rootvg_op_str << " -d " << disk
    end
    converge_by("alt_disk: renaming alternate rootvg #{@new_resource.altdisk_name}") do
      Chef::Log.debug("alt_disk: running command #{alt_rootvg_op_str}")
      alt_rootvg_op=Mixlib::ShellOut.new(alt_rootvg_op_str)
      alt_rootvg_op.run_command
      alt_rootvg_op.error!
      if !alt_rootvg_op.exitstatus
        Chef::Log.fatal("alt_disk: can't cleanup alternate rootvg")
      end
    end
  end
end

# action wakeup
action :wakeup do
  # as far as I know waking up an alternate rootvg automatically change its name to altinst_rootvg
  if @current_resource.exists
    Chef::Log.debug("alt_disk: action wakeup")
    wakeup=false
    disk=get_current_alt()
    # checking if disk is already active
    lspv=shell_out("lspv")
    lspv.stdout.each_line do |a_pv|
      current_pv_a=a_pv.split(" ")
      if current_pv_a[0] == disk
        if current_pv_a[3] == "active"
          wakeup=true
        end
      end
    end
    if disk != "None" and !wakeup
      converge_by("alt_disk: waking up alternate rootvg on disk #{disk}") do
        alt_rootvg_op_str="alt_rootvg_op -W -d #{disk}"
        alt_rootvg_op=Mixlib::ShellOut.new(alt_rootvg_op_str)
        alt_rootvg_op.run_command
        # there are sometimes error when waking up
        #alt_rootvg_op.error!
        if !alt_rootvg_op.exitstatus
          Chef::Log.fatal("alt_disk: can't wakeup alternate rootvg")
        end
      end
    end
  end
end

# action sleep
action :sleep do
  if @current_resource.exists
    Chef::Log.info("alt_disk: action sleep")
    wakeup=false
    disk=get_current_alt()
    # checking if disk is already active
    lspv=shell_out("lspv")
    lspv.stdout.each_line do |a_pv|
      current_pv_a=a_pv.split(" ")
      if current_pv_a[0] == disk
        if current_pv_a[3] == "active"
          wakeup=true
        end
      end
    end
    if disk != "None" and wakeup
      converge_by("alt_disk: putting alternate rootvg in sleep") do
        alt_rootvg_op_str="alt_rootvg_op -S"
        alt_rootvg_op=Mixlib::ShellOut.new(alt_rootvg_op_str)
        alt_rootvg_op.run_command
        # there are sometimes error when waking up
        #alt_rootvg_op.error!
        if !alt_rootvg_op.exitstatus
          Chef::Log.fatal("alt_disk: can't wakeup alternate rootvg")
        end
      end
    end
  end
end

# action customize
action :customize do
  Chef::Log.info("alt_disk: action customize")
  # a resource can be customized only if this one exists
  if @current_resource.exists
    Chef::Log.info("alt_disk: customize")
    disk=get_current_alt()
    customize=false
    unless defined?(@new_resource.image_location)
      customize=false
    else
      customize=true
    end
    if disk != "None" and customize
      converge_by("alt_disk: customize alt_disk (update)") do
        Chef::Log.info("!!!!!! Rungging coommand alt_rootvg_op -C -b update_all -l #{@new_resource.image_location}")
        alt_rootvg_op_str="alt_rootvg_op -C -b update_all -l #{@new_resource.image_location}"
        alt_rootvg_op=Mixlib::ShellOut.new(alt_rootvg_op_str, :timeout => 15000)
        alt_rootvg_op.run_command
        alt_rootvg_op.error!
        Chef::Log.info("!!!!!!")
        if !alt_rootvg_op.exitstatus
          Chef::Log.fatal("alt_disk: can't customize")
        end
      end
    end
  end
end

# find_and_check_disk
# this def is searching a disk usable by alt_disk operation
# if size is lesser than the current rootvg it returns None
# else it return the name of the disk with the criteria below
# type
#  - size : find disk by its size
#  - name : find disk by its name
#  - auto : automatically find disk by criteria
# value
#  - for size : int size of the disk in mb
#  - for name : name of the disk
#  - for auto : equal : first disk of the same size
#               bigger : first disk of greater size
def find_and_check_disk(type,value)
  lspv_root=shell_out("lspv | awk '$3 == \"rootvg\" {print $1}'")
  current_rootvg=lspv_root.stdout
  current_rootvg_size=sizeof_disk(current_rootvg)
  lspv=shell_out("lspv")
  disk="None"
  # type is name
  if type == :name
    lspv.stdout.each_line do |a_pv|
      current_pv_a=a_pv.split(" ")
      if current_pv_a[0] == value
        if current_pv_a[2] == "None"
          Chef::Log.info("alt_disk: disk #{value} is usable")
          disk=current_pv_a[0]
        end
      end
    end
  # type is size
  elsif type == :size
    lspv.stdout.each_line do |a_pv|
      current_pv_a=a_pv.split(" ")
      if current_pv_a[2] == "None"
        this_size=sizeof_disk(current_pv_a[0])
        if this_size == value.to_i
          Chef::Log.debug("alt_disk: empty disk #{current_pv_a[0]} found with a size of #{value}")
          disk=current_pv_a[0]
        end
      end
    end
  # type is auto
  elsif type == :auto
    lspv.stdout.each_line do |a_pv|
      current_pv_a=a_pv.split(" ")
      if current_pv_a[2] == "None"
        this_size=sizeof_disk(current_pv_a[0])
        if value == "equal" and this_size == current_rootvg_size
          Chef::Log.debug("alt_disk: empty disk #{current_pv_a[0]} found with a size of the current rootvg")
          disk=current_pv_a[0]
        end
        if value == "bigger" and this_size > current_rootvg_size
          Chef::Log.debug("alt_disk: empty disk #{current_pv_a[0]} found with a size bigger than the size of the current rootvg")
          disk=current_pv_a[0]
        end
      end
    end
  end
  if disk == "None"
    Chef::Log.debug("alt_disk: cannot find any disk usable for alt_disk")
    return "None"
  else
    Chef::Log.debug("alt_disk: checking size is BIGGER or EQUAL")
    test=check_disk_size(current_rootvg,disk)
    if test == "BIGGER" or test == "EQUAL"
      Chef::Log.debug("alt_disk: disk is BIGGER or EQUAL")
      return disk
    elif test == "LESSER"
      Chef::Log.debug("alt_disk: cannot find any disk usable for alt_disk")
      return "None"
    end
  end
end

# this def is comparing two disk size
def check_disk_size(source,dest)
  Chef::Log.debug("alt_disk: Checking disk size")
  source_size=shell_out("getconf DISK_SIZE /dev/#{source}")
  dest_size=shell_out("getconf DISK_SIZE /dev/#{dest}")
  Chef::Log.debug("alt_disk: comparing "+dest_size.stdout.chomp+" to "+source_size.stdout.chomp)
  int_source_size=source_size.stdout.chomp.to_i
  int_dest_size=dest_size.stdout.chomp.to_i
  if int_dest_size < int_source_size
    Chef::Log.debug("alt_disk: size --> LESSER")
    return "LESSER"
  end
  if int_dest_size > int_source_size
    Chef::Log.debug("alt_disk: size --> BIGGER")
    return "BIGGER"
  end
  if int_dest_size == int_source_size
    Chef::Log.debug("alt_disk: size --> EQUAL")
    return "EQUAL"
  end
end

# this def return disk size
def sizeof_disk(disk)
    disk_size=shell_out("getconf DISK_SIZE /dev/#{disk}")
    return disk_size.stdout.chomp.to_i
end

#this def return the disk of the alternate rootvg
def get_current_alt
  disk="None"
  lspv_altdisk=shell_out("lspv | awk '$3 == \"#{@new_resource.altdisk_name}\"'")
  lspv_altdisk.stdout.each_line do |a_pv|
    current_pv_a=a_pv.split(" ")
    if current_pv_a[2] == @new_resource.altdisk_name
      disk=current_pv_a[0]
    end
  end
  Chef::Log.debug("alt_disk: current_alt #{disk}")
  return disk
end
