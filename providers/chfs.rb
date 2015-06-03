#
# Author:: Vianney Foucault (<vianney.foucault@gmail.com>)
# Cookbook Name:: aix
# Provider:: chfs
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

action :resize do
  if not @current_resource.exists
    Chef::Log.info "Cannot resize fs #{@current_resource.name} - does not exist."
    raise "Cannot resize fs #{@current_resource.name} - does not exist."
  end
  neededspace = Integer.new
  if @new_resource.units == "G"
    @new_resource.size(@new_resource.size / 1024)
  elsif @new_resource.units == "K"
    @new_resource.size(@new_resource.size * 1024)
  end
  if @new_resource.sign == "+"
    neededspace = @new_resource.size
    check_vg_space
  elsif @new_resource.sign == "-"
    check_df_space
  elsif @new_resource.sign.nil?
    if @new_resource.size < @current_resource.size
      check_df_space
    else
      @new_resource.neededspace(@new_resource.size - @current_resource.size)
      check_vg_space
    end
  end
  converge_by("Resizing filesystem #{ @new_resource.name }") do
    resize_fs
  end
end

def resize_fs
  cmd "chfs -a size=#{@new_resource.sign}#{@new_resource.size}M #{@current_resource.name}"
  chuser = Mixlib::ShellOut.new(cmd)
  chuser.valid_exit_codes = 0
  chuser.run_command
  chuser.error!
  chuser.error?
end

def check_vg_space
  if @new_resource.neededspace > @current_resource.vgfreemb
    Chef::Log.info "Cannot resize fs #{@current_resource.name} - not enough free space in volume group."
    raise "Cannot resize fs #{@current_resource.name} - not enough free space in volume group."
  end
end

def check_df_space
  if @new_resource.dffreesize < @current_resource.neededspace
    Chef::Log.info "Cannot resize fs #{@current_resource.name} - not enough free space filesystem."
    raise "Cannot resize fs #{@current_resource.name} - not enough free space filesystem."
  end
end

def load_current_resource
  @current_resource = Chef::Resource::AixChfs.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.exists = false
  if fs_exists?(@current_resource.name)
    @current_resource.exists = true
    load_fs_attributes
    get_vg_freespace
  end
end

def load_fs_attributes
  cmd = Mixlib::ShellOut.new("lsfs -c #{@current_resource.name}")
  cmd.run_command
  cmd.stdout.chomp!
  attr_name = cmd.stdout.lines.first.split(':').map(&:strip).map(&:to_sym)
  attr_value = cmd.stdout.lines.last.split(':').map { |x| if x == "true" ; true ; elsif x == "false" ; false ; elsif x.to_i.to_s === x; x.to_i; else;  x ; end }
  attrs = Hash[attr_name.zip(attr_value)]
  pp attrs
  @current_resource.size(attrs[:Size])
  @current_resource.mountpoint(attrs[:"#MountPoint"])
  @current_resource.lvdevice(attrs[:Device])
  @current_resource.options(attrs[:Options])
  if attrs[:AutoMount] == "yes"
    @current_resource.automount(true)
  else
    @current_resource.automount(false)
  end
end

def get_vg_freespace
  cmd = Mixlib::ShellOut.new("lsvg \$(lslv  \$(lsfs -l {@current_resource.name} | awk '{ print \$1 }' | tail -n 1 | sed -e 's/\/dev\///') | head -n 1 | awk '{ print \$6 }') | egrep '(PP SIZE|FREE PPs)' | awk '{ print \$6}'")
  cmd.run_command
  cmd.stdout.chomp!
  @current_resource.vgppsize(cmd.stdout.lines.first.chomp.to_i)
  @current_resource.vgfreepp(cmd.stdout.lines.last.chomp.to_i)
  @current_resource.vgfreemb(@current_resource.vgppsize * @current_resource.vgfreepp)
end

def get_df_freespace
  cmd = Mixlib::ShellOut.new("df -m {@current_resource.name} | awk '{ print \$3 }' | tail -n 1")
  cmd.run_command
  cmd.stdout.chomp!
  @current_resource.dffreesize(cmd.stdout.lines.first.chomp.to_f - 1 )
end

def fs_exists?(name)
  cmd = Mixlib::ShellOut.new("lsfs #{@current_resource.name}")
  cmd.valid_exit_codes = 0
  cmd.run_command
  !cmd.error?
end
