#
# Author:: Vianney Foucault (<vianney.foucault@gmail.com>)
# Cookbook Name:: idp-aix
# Provider:: aixuser
#
# Copyright:: 2014, The Author
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

action :create do
  if @current_resource.exists
    Chef::Log.info "#{ @new_resource } already exists - nothing to do."
  else
    converge_by("Creating group #{ @new_resource.name }") do
      create_group
    end
  end
end

action :delete do
  if @current_resource.exists
    converge_by("Delete group #{ @new_resource.name }") do
      delete_group
    end
  else
    Chef::Log.info "Group #{ @current_resource.name } doesn't exist - can't delete."
  end
  new_resource.updated_by_last_action(true)
end

#instadm id=1030 admin=false users=svgsys adms=root registry=files

action :update do
  if not @current_resource.exists
    Chef::Log.info "Cannot modify group #{ current_resource.name} - does not exist."
    raise "Cannot modify group #{@current_resource.name} - does not exist."
  else
    attributes = Hash.new
    if @current_resource.gid != @new_resource.gid and not @new_resource.gid.nil?
      attributes[:id] = @new_resource.gid
    end
    if @current_resource.admin != @new_resource.admin and not @new_resource.admin.nil?
      attributes[:admin] = @new_resource.admin
    end
    if @current_resource.users != @new_resource.users and not @new_resource.users.nil?
      attributes[:users] = @new_resource.users.join(',')
    end
    if @current_resource.adms != @new_resource.adms and not @new_resource.adms.nil?
      attributes[:adms] = @new_resource.amds
    end
    if @current_resource.registry != @new_resource.registry and not @new_resource.registry.nil?
      attributes[:registry] = @new_resource.registry
    end
    if attributes.length != 0
      cmd = "chgroup "
      attributes.each do |k,v|
        cmd << "#{k}=\"#{v}\" " if not v.nil?
      end
      cmd << @current_resource.name
      converge_by("Updating group #{@current_resource.name}") do
        chgroup = Mixlib::ShellOut.new(cmd)
        chgroup.valid_exit_codes = 0
        chgroup.run_command
        chgroup.error!
        chgroup.error?
      end
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::AixGroup.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.exists = false
  if group_exists?(@current_resource.name)
    @current_resource.exists = true
    load_group_attributes
  end
end

def load_group_attributes
  lsgroup = Mixlib::ShellOut.new("lsgroup -c #{@current_resource.name}")
  lsgroup.run_command
  attr_name = lsgroup.stdout.lines.first.split(':').map(&:strip).map(&:to_sym)
  attr_value = lsgroup.stdout.lines.last.split(':').map(&:strip).map { |x| if x == "true" ; true ; elsif x == "false" ; false ; else x ; end }
  attrs = Hash[attr_name.zip(attr_value)]
  @current_resource.gid(attrs[:id].to_i)
  @current_resource.admin(attrs[:admin])
  @current_resource.users(attrs[:users])
  @current_resource.adms(attrs[:adms])
  @current_resource.registry(attrs[:registry])
end

def group_exists?(name)
  lsgroup = Mixlib::ShellOut.new("lsgroup -c #{@current_resource.name}")
  lsgroup.valid_exit_codes = 0
  lsgroup.run_command
  !lsgroup.error?
end

def create_group
  attributes = Hash.new
  attributes[:id] = @new_resource.gid ? "id=#{@new_resource.gid}" : ''
  attributes[:admin] = @new_resource.admin ? "admin=#{@new_resource.admin}" : ''
  attributes[:users] = @new_resource.users ? "users=#{@new_resource.users.join(',')}" : ''
  attributes[:adms] = @new_resource.adms ? "adms=#{@new_resource.adms}" : ''
  attributes[:registry] = @new_resource.registry ? "registry=#{@new_resource.registry}" : ''
  if attributes.length != 0
    cmd = "mkgroup "
    attributes.each do |k,v|
      cmd << "#{v} " if not v.nil?
    end
    cmd << @current_resource.name
    mkgroup = Mixlib::ShellOut.new(cmd)
    mkgroup.valid_exit_codes = 0
    mkgroup.run_command
    mkgroup.error!
    mkgroup.error?
  end
  new_resource.updated_by_last_action(true)
end

def delete_user
  command = "rmgroup -p #{@current_resource.name}"
  rmgroup = Mixlib::ShellOut.new(command)
  rmgroup.valid_exit_codes = 0
  rmgroup.run_command
  rmgroup.error!
  rmgroup.error?
end

def update_user_pwd
  cmd = "echo #{@new_resource.name}:#{@new_resource.crypt} | chpasswd -c -e"
  chpass = Mixlib::ShellOut.new(cmd)
  chpass.valid_exit_codes = 0
  chpass.run_command
  chpass.error!
  chpass.error?
end
