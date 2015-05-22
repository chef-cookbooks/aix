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
    converge_by("Creating user #{ @new_resource.name }") do
      create_user
    end
  end
end

action :delete do
  if @current_resource.exists
    converge_by("Delete user #{ @new_resource.name }") do
      delete_user
    end
  else
    Chef::Log.info "User #{ @current_resource.name } doesn't exist - can't delete."
  end
  new_resource.updated_by_last_action(true)
end

action :update do
  if not @current_resource.exists
    Chef::Log.info "Cannot modify user toto - does not exist."
    raise "Cannot modify user #{@current_resource.name} - does not exist."
  else
    attributes = Hash.new
    udpate_password = false
    if @current_resource.uid != @new_resource.uid and not @new_resource.uid.nil?
      attributes[:id] = @new_resource.uid
    end
    if @current_resource.pgrp != @new_resource.pgrp and not @new_resource.pgrp.nil?
      attributes[:pgrp] = @new_resource.pgrp
    end
    if @current_resource.groups != @new_resource.groups and not @new_resource.groups.nil?
      if @new_resource.groups.is_a?(Array)
        attributes[:groups] = @new_resource.groups.join(',')
      else
        attributes[:groups] = @new_resource.groups
      end
    end
    if @current_resource.home != @new_resource.home and not @new_resource.home.nil?
      attributes[:home] = @new_resource.home
    end
    if @current_resource.shell != @new_resource.shell and not @new_resource.shell.nil?
      attributes[:shell] = @new_resource.shell
    end
    if @current_resource.gecos != @new_resource.gecos and not @new_resource.gecos.nil?
      attributes[:gecos] = @new_resource.gecos
    end
    if @current_resource.login != @new_resource.login and not @new_resource.login.nil?
      attributes[:login] = @new_resource.login
    end
    if @current_resource.su != @new_resource.su and not @new_resource.su.nil?
      attributes[:su] = @new_resource.su
    end
    if @current_resource.rlogin != @new_resource.rlogin and not @new_resource.rlogin.nil?
      attributes[:rlogin] = @new_resource.rlogin
    end
    if @current_resource.daemon != @new_resource.daemon and not @new_resource.daemon.nil?
      attributes[:daemon] = @new_resource.daemon
    end
    if @current_resource.admin != @new_resource.admin and not @new_resource.admin.nil?
      attributes[:admin] = @new_resource.admin
    end
    if @current_resource.sugroups != @new_resource.sugroups and not @new_resource.sugroups.nil?
      attributes[:sugroups] = @new_resource.sugroups
    end
    if @current_resource.admgroups != @new_resource.admgroups and not @new_resource.admgroups.nil?
      attributes[:admgroups] = @new_resource.admgroups
    end
    if @current_resource.tpath != @new_resource.tpath and not @new_resource.tpath.nil?
      attributes[:tpath] = @new_resource.tpath
    end
    if @current_resource.ttys != @new_resource.ttys and not @new_resource.ttys.nil?
      attributes[:ttys] = @new_resource.ttys
    end
    if @current_resource.expires != @new_resource.expires and not @new_resource.expires.nil?
      attributes[:expires] = @new_resource.expires
    end
    if @current_resource.auth1 != @new_resource.auth1 and not @new_resource.auth1.nil?
      attributes[:auth1] = @new_resource.auth1
    end
    if @current_resource.auth2 != @new_resource.auth2 and not @new_resource.auth2.nil?
      attributes[:auth2] = @new_resource.auth2
    end
    if @current_resource.umask != @new_resource.umask and not @new_resource.umask.nil?
      attributes[:umask] = @new_resource.umask
    end
    if @current_resource.registry != @new_resource.registry and not @new_resource.registry.nil?
      attributes[:registry] = @new_resource.registry
    end
    if @current_resource.SYSTEM != @new_resource.SYSTEM and not @new_resource.SYSTEM.nil?
      attributes[:SYSTEM] = @new_resource.SYSTEM
    end
    if @current_resource.logintimes != @new_resource.logintimes and not @new_resource.logintimes.nil?
      attributes[:logintimes] = @new_resource.logintimes
    end
    if @current_resource.loginretries != @new_resource.loginretries and not @new_resource.loginretries.nil?
      attributes[:loginretries] = @new_resource.loginretries
    end
    if @current_resource.pwdwarntime != @new_resource.pwdwarntime and not @new_resource.pwdwarntime.nil?
      attributes[:pwdwarntime] = @new_resource.pwdwarntime
    end
    if @current_resource.account_locked != @new_resource.account_locked and not @new_resource.account_locked.nil?
      attributes[:account_locked] = @new_resource.account_locked
    end
    if @current_resource.minage != @new_resource.minage and not @new_resource.minage.nil?
      attributes[:minage] = @new_resource.minage
    end
    if @current_resource.maxage != @new_resource.maxage and not @new_resource.maxage.nil?
      attributes[:maxage] = @new_resource.maxage
    end
    if @current_resource.maxexpired != @new_resource.maxexpired and not @new_resource.maxexpired.nil?
      attributes[:maxexpired] = @new_resource.maxexpired
    end
    if @current_resource.minalpha != @new_resource.minalpha and not @new_resource.minalpha.nil?
      attributes[:minalpha] = @new_resource.minalpha
    end
    if @current_resource.minloweralpha != @new_resource.minloweralpha and not @new_resource.minloweralpha.nil?
      attributes[:minloweralpha] = @new_resource.minloweralpha
    end
    if @current_resource.minupperalpha != @new_resource.minupperalpha and not @new_resource.minupperalpha.nil?
      attributes[:minupperalpha] = @new_resource.minupperalpha
    end
    if @current_resource.minother != @new_resource.minother and not @new_resource.minother.nil?
      attributes[:minother] = @new_resource.minother
    end
    if @current_resource.mindigit != @new_resource.mindigit and not @new_resource.mindigit.nil?
      attributes[:mindigit] = @new_resource.mindigit
    end
    if @current_resource.minspecialchar != @new_resource.minspecialchar and not @new_resource.minspecialchar.nil?
      attributes[:minspecialchar] = @new_resource.minspecialchar
    end
    if @current_resource.mindiff != @new_resource.mindiff and not @new_resource.mindiff.nil?
      attributes[:mindiff] = @new_resource.mindiff
    end
    if @current_resource.maxrepeats != @new_resource.maxrepeats and not @new_resource.maxrepeats.nil?
      attributes[:maxrepeats] = @new_resource.maxrepeats
    end
    if @current_resource.minlen != @new_resource.minlen and not @new_resource.minlen.nil?
      attributes[:minlen] = @new_resource.minlen
    end
    if @current_resource.histexpire != @new_resource.histexpire and not @new_resource.histexpire.nil?
      attributes[:histexpire] = @new_resource.histexpire
    end
    if @current_resource.histsize != @new_resource.histsize and not @new_resource.histsize.nil?
      attributes[:histsize] = @new_resource.histsize
    end
    if @current_resource.pwdchecks != @new_resource.pwdchecks and not @new_resource.pwdchecks.nil?
      attributes[:pwdchecks] = @new_resource.pwdchecks
    end
    if @current_resource.dictionlist != @new_resource.dictionlist and not @new_resource.dictionlist.nil?
      attributes[:dictionlist] = @new_resource.dictionlist
    end
    if @current_resource.default_roles != @new_resource.default_roles and not @new_resource.default_roles.nil?
      attributes[:default_roles] = @new_resource.default_roles
    end
    if @current_resource.fsize != @new_resource.fsize and not @new_resource.fsize.nil?
      attributes[:fsize] = @new_resource.fsize
    end
    if @current_resource.cpu != @new_resource.cpu and not @new_resource.cpu.nil?
      attributes[:cpu] = @new_resource.cpu
    end
    if @current_resource.data != @new_resource.data and not @new_resource.data.nil?
      attributes[:data] = @new_resource.data
    end
    if @current_resource.stack != @new_resource.stack and not @new_resource.stack.nil?
      attributes[:stack] = @new_resource.stack
    end
    if @current_resource.core != @new_resource.core and not @new_resource.core.nil?
      attributes[:core] = @new_resource.core
    end
    if @current_resource.rss != @new_resource.rss and not @new_resource.rss.nil?
      attributes[:rss] = @new_resource.rss
    end
    if @current_resource.nofiles != @new_resource.nofiles and not @new_resource.nofiles.nil?
      attributes[:nofiles] = @new_resource.nofiles
    end
    if @current_resource.roles != @new_resource.roles and not @new_resource.roles.nil?
      attributes[:roles] = @new_resource.roles
    end
    if @current_resource.crypt != @new_resource.crypt and not @new_resource.crypt.nil?
      update_password = true
    end
    if attributes.length != 0
      cmd = "chuser "
      attributes.each do |k,v|
        cmd << "#{k}=\"#{v}\" " if not v.nil?
      end
      cmd << @current_resource.name
      converge_by("Updating user #{@current_resource.name}") do
        chuser = Mixlib::ShellOut.new(cmd)
        chuser.valid_exit_codes = 0
        chuser.run_command
        chuser.error!
        chuser.error?
      end
    end
    if update_password
      converge_by("Updating password for user #{@current_resource.name}") do
        update_user_pwd
      end
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::AixUser.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.exists = false
  if user_exists?(@current_resource.name)
    @current_resource.exists = true
    load_user_attributes
  end
end

def load_user_attributes
  lsuser = Mixlib::ShellOut.new("lsuser -c #{@current_resource.name}")
  lsuser.run_command
  attr_name = lsuser.stdout.lines.first.split(':').map(&:strip).map(&:to_sym)
  attr_value = lsuser.stdout.lines.last.split(':').map(&:strip).map { |x| if x == "true" ; true ; elsif x == "false" ; false ; else x ; end }
  attrs = Hash[attr_name.zip(attr_value)]
  @current_resource.uid(attrs[:id].to_i)
  @current_resource.pgrp(attrs[:pgrp])
  @current_resource.groups(attrs[:groups])
  @current_resource.home(attrs[:home])
  @current_resource.shell(attrs[:shell])
  @current_resource.gecos(attrs[:gecos])
  @current_resource.login(attrs[:login])
  @current_resource.su(attrs[:su])
  @current_resource.rlogin(attrs[:rlogin])
  @current_resource.daemon(attrs[:daemon])
  @current_resource.admin(attrs[:admin])
  @current_resource.sugroups(attrs[:sugroups])
  @current_resource.admgroups(attrs[:admgroups])
  @current_resource.tpath(attrs[:tpath])
  @current_resource.ttys(attrs[:ttys])
  @current_resource.expires(attrs[:expires].to_i)
  @current_resource.auth1(attrs[:auth1])
  @current_resource.auth2(attrs[:auth2])
  @current_resource.umask(attrs[:umask].to_i)
  @current_resource.registry(attrs[:registry])
  @current_resource.SYSTEM(attrs[:SYSTEM])
  @current_resource.logintimes(attrs[:logintimes])
  @current_resource.loginretries(attrs[:loginretries].to_i)
  @current_resource.pwdwarntime(attrs[:pwdwarntime].to_i)
  @current_resource.account_locked(attrs[:account_locked])
  @current_resource.minage(attrs[:minage].to_i)
  @current_resource.maxage(attrs[:maxage].to_i)
  @current_resource.maxexpired(attrs[:maxexpired].to_i)
  @current_resource.minalpha(attrs[:minalpha].to_i)
  @current_resource.minloweralpha(attrs[:minloweralpha].to_i)
  @current_resource.minupperalpha(attrs[:minupperalpha].to_i)
  @current_resource.minother(attrs[:minother].to_i)
  @current_resource.mindigit(attrs[:mindigit].to_i)
  @current_resource.minspecialchar(attrs[:minspecialchar].to_i)
  @current_resource.mindiff(attrs[:mindiff].to_i)
  @current_resource.maxrepeats(attrs[:maxrepeats].to_i)
  @current_resource.minlen(attrs[:minlen].to_i)
  @current_resource.histexpire(attrs[:histexpire].to_i)
  @current_resource.histsize(attrs[:histsize].to_i)
  @current_resource.pwdchecks(attrs[:pwdchecks])
  @current_resource.dictionlist(attrs[:dictionlist])
  @current_resource.default_roles(attrs[:default_roles])
  @current_resource.fsize(attrs[:fsize].to_i)
  @current_resource.cpu(attrs[:cpu].to_i)
  @current_resource.data(attrs[:data].to_i)
  @current_resource.stack(attrs[:stack].to_i)
  @current_resource.core(attrs[:core].to_i)
  @current_resource.rss(attrs[:rss].to_i)
  @current_resource.nofiles(attrs[:nofiles].to_i)
  @current_resource.roles(attrs[:roles])
  pwdcmd = "grep -p #{@current_resource.name} /etc/security/passwd | grep password"
  userpwd = Mixlib::ShellOut.new(pwdcmd)
  userpwd.run_command
  if userpwd.exitstatus == 0
    crypt = userpwd.stdout.split('=')[1].delete(' ').chomp()
    if crypt != "*"
      @current_resource.crypt(crypt)
    end
  end
end

def user_exists?(name)
  lsuser = Mixlib::ShellOut.new("lsuser -c #{@current_resource.name}")
  lsuser.valid_exit_codes = 0
  lsuser.run_command
  !lsuser.error?
end

def create_user
  attributes = Hash.new
  attributes[:id] = @new_resource.uid ? "id=#{@new_resource.uid}" : ''
  attributes[:pgrp] = @new_resource.pgrp ? "pgrp=#{@new_resource.pgrp}" : ''
  if @new_resource.groups.is_a?(Array)
    attributes[:groups] = @new_resource.groups ? "groups=#{@new_resource.groups.join(',')}" : ''
  else
    attributes[:groups] = @new_resource.groups ? "groups=#{@new_resource.groups}" : ''
  end
  attributes[:home] = @new_resource.home ? "home=#{@new_resource.home}" : ''
  attributes[:shell] = @new_resource.shell ? "shell=#{@new_resource.shell}" : ''
  attributes[:gecos] = @new_resource.gecos ? "gecos=\"#{@new_resource.gecos}\"" : ''
  attributes[:login] = @new_resource.login ? "login=#{@new_resource.login}" : ''
  attributes[:su] = @new_resource.su ? "su=#{@new_resource.su}" : ''
  attributes[:rlogin] = @new_resource.rlogin ? "rlogin=#{@new_resource.rlogin}" : ''
  attributes[:daemon] = @new_resource.daemon ? "daemon=#{@new_resource.daemon}" : ''
  attributes[:admin] = @new_resource.admin ? "admin=#{@new_resource.admin}" : ''
  attributes[:sugroups] = @new_resource.sugroups ? "sugroups=#{@new_resource.sugroups}" : ''
  attributes[:admgroups] = @new_resource.admgroups ? "admgroups=#{@new_resource.admgroups}" : ''
  attributes[:tpath] = @new_resource.tpath ? "tpath=#{@new_resource.tpath}" : ''
  attributes[:ttys] = @new_resource.ttys ? "ttys=#{@new_resource.ttys}" : ''
  attributes[:expires] = @new_resource.expires ? "expires=#{@new_resource.expires}" : ''
  attributes[:auth1] = @new_resource.auth1 ? "auth1=#{@new_resource.auth1}" : ''
  attributes[:auth2] = @new_resource.auth2 ? "auth2=#{@new_resource.auth2}" : ''
  attributes[:umask] = @new_resource.umask ? "umask=#{@new_resource.umask}" : ''
  attributes[:registry] = @new_resource.registry ? "registry=#{@new_resource.registry}" : ''
  attributes[:SYSTEM] = @new_resource.SYSTEM ? "SYSTEM=#{@new_resource.SYSTEM}" : ''
  attributes[:logintimes] = @new_resource.logintimes ? "logintimes=#{@new_resource.logintimes}" : ''
  attributes[:loginretries] = @new_resource.loginretries ? "loginretries=#{@new_resource.loginretries}" : ''
  attributes[:pwdwarntime] = @new_resource.pwdwarntime ? "pwdwarntime=#{@new_resource.pwdwarntime}" : ''
  attributes[:account_locked] = @new_resource.account_locked ? "account_locked=#{@new_resource.account_locked}" : ''
  attributes[:minage] = @new_resource.minage ? "minage=#{@new_resource.minage}" : ''
  attributes[:maxage] = @new_resource.maxage ? "maxage=#{@new_resource.maxage}" : ''
  attributes[:maxexpired] = @new_resource.maxexpired ? "maxexpired=#{@new_resource.maxexpired}" : ''
  attributes[:minalpha] = @new_resource.minalpha ? "minalpha=#{@new_resource.minalpha}" : ''
  attributes[:minloweralpha] = @new_resource.minloweralpha ? "minloweralpha=#{@new_resource.minloweralpha}" : ''
  attributes[:minupperalpha] = @new_resource.minupperalpha ? "minupperalpha=#{@new_resource.minupperalpha}" : ''
  attributes[:minother] = @new_resource.minother ? "minother=#{@new_resource.minother}" : ''
  attributes[:mindigit] = @new_resource.mindigit ? "mindigit=#{@new_resource.mindigit}" : ''
  attributes[:minspecialchar] = @new_resource.minspecialchar ? "minspecialchar=#{@new_resource.minspecialchar}" : ''
  attributes[:mindiff] = @new_resource.mindiff ? "mindiff=#{@new_resource.mindiff}" : ''
  attributes[:maxrepeats] = @new_resource.maxrepeats ? "maxrepeats=#{@new_resource.maxrepeats}" : ''
  attributes[:minlen] = @new_resource.minlen ? "minlen=#{@new_resource.minlen}" : ''
  attributes[:histexpire] = @new_resource.histexpire ? "histexpire=#{@new_resource.histexpire}" : ''
  attributes[:histsize] = @new_resource.histsize ? "histsize=#{@new_resource.histsize}" : ''
  attributes[:pwdchecks] = @new_resource.pwdchecks ? "pwdchecks=#{@new_resource.pwdchecks}" : ''
  attributes[:dictionlist] = @new_resource.dictionlist ? "dictionlist=#{@new_resource.dictionlist}" : ''
  attributes[:default_roles] = @new_resource.default_roles ? "default_roles=#{@new_resource.default_roles}" : ''
  attributes[:fsize] = @new_resource.fsize ? "fsize=#{@new_resource.fsize}" : ''
  attributes[:cpu] = @new_resource.cpu ? "cpu=#{@new_resource.cpu}" : ''
  attributes[:data] = @new_resource.data ? "data=#{@new_resource.data}" : ''
  attributes[:stack] = @new_resource.stack ? "stack=#{@new_resource.stack}" : ''
  attributes[:core] = @new_resource.core ? "core=#{@new_resource.core}" : ''
  attributes[:rss] = @new_resource.rss ? "rss=#{@new_resource.rss}" : ''
  attributes[:nofiles] = @new_resource.nofiles ? "nofiles=#{@new_resource.nofiles}" : ''
  attributes[:roles] = @new_resource.roles ? "roles=#{@new_resource.roles}" : ''
  if attributes.length != 0
    cmd = "mkuser "
    attributes.each do |k,v|
      cmd << "#{v} " if not v.nil?
    end
    cmd << @current_resource.name
    mkuser = Mixlib::ShellOut.new(cmd)
    mkuser.valid_exit_codes = 0
    mkuser.run_command
    mkuser.error!
    mkuser.error?
    update_user_pwd
  end
  new_resource.updated_by_last_action(true)
end

def delete_user
  command = "rmuser -p #{@current_resource.name}"
  rmuser = Mixlib::ShellOut.new(command)
  rmuser.valid_exit_codes = 0
  rmuser.run_command
  rmuser.error!
  rmuser.error?
end

def update_user_pwd
  cmd = "echo #{@new_resource.name}:#{@new_resource.crypt} | chpasswd -c -e"
  chpass = Mixlib::ShellOut.new(cmd)
  chpass.valid_exit_codes = 0
  chpass.run_command
  chpass.error!
  chpass.error?
end
