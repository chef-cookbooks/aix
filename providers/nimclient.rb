# Author:: Benoit Creau (<benoit.creau@chmod666.org>)
# Cookbook Name:: aix
# Provider:: nimclient
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

# nim client reminder
# nimclient -o allocate -a lpp_source=<lpp_source_name>                              # allocate a resource
# nimclient -l -c resources <client_name>                                            # check allocate resource
# nimclient -o cust -a lpp_source=<lpp_source_name> -a fixes=update_all              # update_all from lpp_source
# nimclient -l -L <client_name>                                                      # list resource available for this client
# nimclient -o cust -a lpp_source=<lpp_source_name> -a filesets=<list_of_filesets>   # install specifics filesets
# nimclient -o reset                                                                 # reset the client
# nimclient -Fo reset                                                                # force client reset
# nimclient -l -p -s pull_ops                                                        # list allowed pull operations
# nimclient -o maint_boot -a spot=<spot_name>                                        # enable maintenance boot
# nimclient -o cust -a installp_bundle=<bundle_name> -a lpp_source=<lpp_source_name> # install installp_bundle
# nimclient -ll <lpp_source>                                                         # same as lsnim -l <lpp_source>
# nimclient -o showres -a resource=7100-03-05-1524-lpp_source                        # showres
# nimclient -o deallocate                                                            # deallocate
# nimclient -d                                                                       # synchronize date with the nim master
# nimclient -p									     # enable push operation
# nimclient -P                                                                       # disable push operation

# Support whyrun
def whyrun_supported?
  true
end

# action set_date
# set the client date to that of the master
action :set_date do
  nimclient_s = 'nimclient -d'
  converge_by("nimclient: set the client's date to that of the master") do
    nimclient = Mixlib::ShellOut.new(nimclient_s)
    nimclient.valid_exit_codes = 0
    nimclient.run_command
    nimclient.error!
    nimclient.error?
  end
end

# action enable push
# enable push operation from client
action :enable_push do
  nimclient_s = 'nimclient -p'
  # enable push if push is disabled
  ps = shell_out('ps -ef | grep nimsh')
  if ps.stdout.include? '-P'
    converge_by('nimclient: enable push operation from client') do
      nimclient = Mixlib::ShellOut.new(nimclient_s)
      nimclient.valid_exit_codes = 0
      nimclient.run_command
      nimclient.error!
      nimclient.error?
    end
  end
end

# action disable push
# disable push operation from client
action :disable_push do
  nimclient_s = 'nimclient -P'
  ps = shell_out('ps -ef | grep nimsh')
  unless ps.stdout.include? '-P'
    converge_by('nimclient: disable push operation from client') do
      nimclient = Mixlib::ShellOut.new(nimclient_s)
      nimclient.valid_exit_codes = 0
      nimclient.run_command
      nimclient.error!
      nimclient.error?
    end
  end
end

# action enable crypto
# enable cryto of nimsh
action :enable_crypto do
  nimclient_s = 'nimclient -c'
  ps = shell_out('ps -ef | grep nimsh')
  unless ps.stdout.include? '-c'
    converge_by('nimclient: enable nimsh crypto') do
      nimclient = Mixlib::ShellOut.new(nimclient_s)
      nimclient.valid_exit_codes = 0
      nimclient.run_command
      nimclient.error!
      nimclient.error?
    end
  end
end

# action disable  crypto
#  disable crypto of nimsh
action :disable_crypto do
  nimclient_s = 'nimclient -C'
  ps = shell_out('ps -ef | grep nimsh')
  if ps.stdout.include? '-c'
    converge_by('nimclient: disable nimsh crypto') do
      nimclient = Mixlib::ShellOut.new(nimclient_s)
      nimclient.valid_exit_codes = 0
      nimclient.run_command
      nimclient.error!
      nimclient.error?
    end
  end
end

# action allocate
action :allocate do
  # Example of nimclient
  # nimclient -o allocate -a lpp_source=mylpp_source -a spot=my_spot -a installp_bundler=my_installpbundle
  nimclient_s = 'nimclient -o allocate'
  lpp_source = @new_resource.lpp_source
  unless lpp_source.nil?
    if resource_exists(lpp_source)
      unless is_resource_allocated(lpp_source, 'lpp_source')
        nimclient_s = nimclient_s << ' -a lpp_source=' << lpp_source
      end
    end
  end

  spot = @new_resource.spot
  unless spot.nil?
    if resource_exists(spot)
      unless is_resource_allocated(spot, 'spot')
        nimclient_s = nimclient_s << ' -a spot=' << spot
      end
    end
  end

  installp_bundle = @new_resource.installp_bundle
  unless installp_bundle.nil?
    if resource_exists(installp_bundle)
      unless is_resource_allocated(installp_bundle, 'installp_bundle')
        nimclient_s = nimclient_s << ' -a installp_bundle=' << installp_bundle
      end
    end
  end

  # converge here
  # don't converge if there is nothing to allocate
  if nimclient_s != 'nimclient -o allocate'
    converge_by("nimclient: allocating resources \"#{nimclient_s}\"") do
      nimclient = Mixlib::ShellOut.new(nimclient_s)
      nimclient.valid_exit_codes = 0
      nimclient.run_command
      nimclient.error!
      nimclient.error?
    end
  end
end

# action maint_boot
action :maint_boot do
  # converging by default
  do_not_converge = false

  standalone = shell_out("nimclient -ll #{node['hostname']}").stdout
  standalone.each_line do |standalone_l|
    standalone_a = standalone_l.split('=')
    stanza = standalone_a[0].to_s.strip
    value = standalone_a[1].to_s.strip
    Chef::Log.debug("nimclient: compare |#{stanza}| vs |Cstate|, |#{value}| vs |maintenance boot has been enabled|")
    if stanza == 'Cstate'
      if value == 'maintenance boot has been enabled'
        do_not_converge = true
        break
      end
    end
  end

  spot = @new_resource.spot
  nimclient_s = 'nimclient -o maint_boot'
  unless spot.nil?
    nimclient_s = nimclient_s << ' -a spot=' << spot if resource_exists(spot)
  end

  if nimclient_s != 'nimclient -o maint_boot'
    unless do_not_converge
      converge_by("nimclient: maint_boot \"#{nimclient_s}\"") do
        nimclient = Mixlib::ShellOut.new(nimclient_s)
        nimclient.valid_exit_codes = 0
        nimclient.run_command
        nimclient.error!
        nimclient.error?
      end
    end
  end
end

# action bos_inst
action :bos_inst do
  # converging by default
  do_not_converge = false

  standalone = shell_out("nimclient -ll #{node['hostname']}").stdout
  standalone.each_line do |standalone_l|
    standalone_a = standalone_l.split('=')
    stanza = standalone_a[0].to_s.strip
    value = standalone_a[1].to_s.strip
    Chef::Log.debug("nimclient: compare |#{stanza}| vs |Cstate|, |#{value}| vs |maintenance boot has been enabled|")
    if stanza == 'Cstate'
      if value == 'BOS installation has been enabled'
        do_not_converge = true
        break
      end
    end
  end

  nimclient_s = 'nimclient -o bos_inst -a accept_licenses=yes'

  spot = @new_resource.spot
  unless spot.nil?
    nimclient_s = nimclient_s << ' -a spot=' << spot if resource_exists(spot)
  end

  lpp_source = @new_resource.lpp_source
  unless lpp_source.nil?
    if resource_exists(lpp_source)
      nimclient_s = nimclient_s << ' -a lpp_source=' << lpp_source
    end
  end

  if nimclient_s != 'nimclient -o bos_inst'
    unless do_not_converge
      converge_by("nimclient: bos_inst \"#{nimclient_s}\"") do
        nimclient = Mixlib::ShellOut.new(nimclient_s)
        nimclient.valid_exit_codes = 0
        nimclient.run_command
        nimclient.error!
        nimclient.error?
      end
    end
  end
end

# action cust
action :cust do
  # Example of nimclient
  # nimclient -o cust -a installp_flags=agXYv -a fixes=update_all
  # cust can be empty, converging if nothing
  nimclient_s = 'nimclient -o cust'
  # converging by default
  do_not_converge = false

  # getting lpp_source
  lpp_source = @new_resource.lpp_source
  unless lpp_source.nil?
    if lpp_source == 'next_sp' || lpp_source == 'next_tl' || lpp_source == 'latest_tl' || lpp_source == 'latest_sp'
      lpp_source_array = lpp_source.split('_')
      time = lpp_source_array[0]
      type = lpp_source_array[1]
      lpp_source = find_resource(type, time)
    end
    if resource_exists(lpp_source)
      nimclient_s = nimclient_s << ' -a lpp_source=' << lpp_source
    end
  end

  # getting spot (not need to find here)
  spot = @new_resource.spot
  unless spot.nil?
    nimclient_s = nimclient_s << ' -a spot=' << spot if resource_exists(spot)
  end

  # getting installp bundle
  installp_bundle = @new_resource.installp_bundle
  unless installp_bundle.nil?
    if resource_exists(installp_bundle)
      nimclient_s = nimclient_s << ' -a installp_bundle=' << installp_bundle
    end
  end

  # getting installp flags
  installp_flags = @new_resource.installp_flags
  unless installp_flags.nil?
    nimclient_s = nimclient_s << " -a installp_flags=\"" << installp_flags << "\""
  end

  # getting fixes
  fixes = @new_resource.fixes
  nimclient_s = nimclient_s << " -a fixes=\"" << fixes << "\"" unless fixes.nil?

  # getting filesets
  filesets = @new_resource.filesets
  unless filesets.nil?
    filesets = check_filesets(filesets, lpp_source)
    if filesets.any?
      nimclient_s = nimclient_s << " -a filesets=\""
      filesets.each_with_index do |a_fileset, i|
        if i == (filesets.size - 1)
          nimclient_s = nimclient_s << a_fileset
        else
          # list of fileset separated by a space
          nimclient_s = nimclient_s << a_fileset << ' '
        end
      end
      nimclient_s = nimclient_s << "\""
    else
      do_not_converge = true
    end
  end

  # command to run is build here
  Chef::Log.debug("nimclient: command build is \"#{nimclient_s}\"")

  # not converging if current oslevel equal to lpp_source selected for update_all operation only
  if fixes == 'update_all'
    current_oslevel = shell_out('oslevel -s').stdout.chomp
    # slincing to remove -lpp_source string
    lpp_source_oslevel = lpp_source.slice!(0..14)
    Chef::Log.debug("nimclient: checking oslevel #{current_oslevel} vs lpp_source oslevel #{lpp_source_oslevel}")
    do_not_converge = true if lpp_source_oslevel == current_oslevel
  end

  # converge here
  unless do_not_converge
    converge_by("nimclient cust operation: \"#{nimclient_s}\"") do
      nimclient = Mixlib::ShellOut.new(nimclient_s, timeout: 7200)
      nimclient.valid_exit_codes = 0
      nimclient.run_command
      nimclient.error!
      nimclient.error?
    end
  end
end

# action deallocate
# for reset and deallocate we always use the force option (-F)
action :deallocate do
  converge_by("nimclient: deallocating all resources for client #{node['hostname']}") do
    nimclient_s = 'nimclient -Fo deallocate -a subclass=all'
    nimclient = Mixlib::ShellOut.new(nimclient_s)
    nimclient.valid_exit_codes = 0
    nimclient.run_command
    nimclient.error!
    nimclient.error?
  end
end

# action reset
# for reset and deallocate we always use the force option (-F)
action :reset do
  converge_by("nimclient: reseting client #{node['hostname']}") do
    nimclient_s = 'nimclient -Fo reset'
    nimclient = Mixlib::ShellOut.new(nimclient_s)
    nimclient.valid_exit_codes = 0
    nimclient.run_command
    nimclient.error!
    nimclient.error?
  end
end

# this function is used to search a lpp_source resource
# find_resource("sp","latest") --> search the latest available service pack for your system
# find_resource("sp","next")   --> search the next available service pack for your system
# find_resource("tl","latest") --> search the latest available technology level for your system
# find_resource("tl","next")   --> search the next available technology level for your system
def find_resource(type, time)
  Chef::Log.debug("nimclient: finding #{time} #{type}")
  # not performing any test on this shell
  current_oslevel = shell_out('oslevel -s').stdout.split('-')
  available_lppsource = shell_out("nimclient -l -t lpp_source -L #{node['hostname']} | awk '{print $1}' | sort -n").stdout
  # this command should show an outpout like this on
  # 7100-01-01-1210-lppsource
  # 7100-01-02-1415-lppsource
  # 7100-03-04-1415-lppsource
  # 7100-03-05-1514-lppsource
  aixlevel = current_oslevel[0]
  tllevel = current_oslevel[1]
  splevel = current_oslevel[2]
  lppsource = ''
  if type == 'tl'
    # reading output until I have found the good tl
    available_lppsource.each_line do |line|
      a_line = line.split('-')
      if a_line[0] == aixlevel && a_line[1] > tllevel
        lppsource = line
        break if (time == 'next')
      end
    end
  elsif type == 'sp'
    # reading output until I have found the good sp
    available_lppsource.each_line do |line|
      a_line = line.split('-')
      if a_line[0] == aixlevel && a_line[1] == tllevel && a_line[2] > splevel
        lppsource = line
        break if (time == 'next')
      end
    end
  end
  if lppsource.empty?
    Chef::Log.debug("nimclient: server already to the #{time} #{type}, or not lpp_source were found")
    # setting lpp_source to current oslevel
    lpp_source = current_oslevel[0] << '-' << current_oslevel[1] << '-' << current_oslevel[2] << '-' << current_oslevel[3].chomp << '-lpp_source'
  else
    Chef::Log.debug("nimclient: we found the #{time} lpp_source, #{lppsource} will be utilized")
    # chomp the return, we need to remove newline here
    return lppsource.chomp
  end
end

# check if a nim resource exists or not
# maybe we can change something here it's not a very fast method
def resource_exists(name)
  resources = shell_out("nimclient -l | awk '{print $1}'").stdout
  found = false
  resources.each_line do |resource|
    resource = resource.chomp
    Chef::Log.debug("nimclient: compare |#{name}| vs |#{resource}|")
    if name == resource.chomp
      found = true
      break
    end
  end
  found
end

# check if list of fileset are in the version of a lpp_source
# return a list of fileset that can be updated or installed  with this lpp_source
def check_filesets(filesets, resource)
  filesets_return = []
  lpp_version = ''
  showres_version = '0'
  showres = shell_out("nimclient -o showres -a resource=#{resource}").stdout
  # is there a _all_fileset the filesets
  # if you are entering a fileset containing other fileset
  # here i build the list of fileset for this fileset
  all_filesets = []
  filesets.each do |a_fileset|
    showres.each_line do |s_fileset|
      if s_fileset.include? a_fileset
        # don't include the "master" fileset
        if s_fileset.include? '_all_filesets'
          next
        else
          get_fileset = s_fileset.split(':')[1].split(' ')[0]
          # if there are multiple versions, so multiple line just include the fileset one time
          all_filesets.push(get_fileset) unless all_filesets.include? get_fileset
        end
      end
    end
  end
  filesets = all_filesets
  filesets.each do |a_fileset|
    lslpp = shell_out("lslpp -qLc #{a_fileset}")
    # if lslpp return is not 0 we consider that this fileset is not installed and we will check if it exist in the lpp_source
    if lslpp.exitstatus != 0
      Chef::Log.debug("nimclient: fileset #{a_fileset} is not installed on this host")
      # does the filesets exists in th lpp_source
      filesets_return.push(a_fileset)
    else
      lpp_version = lslpp.stdout.split(':')[2]
      showres.each_line do |s_fileset|
        if s_fileset.include? a_fileset
          next if s_fileset.include? '_all_filesets'
          version_i = s_fileset.split(' ')[-1].tr('.', '')
          showres_i = showres_version.tr('.', '')
          Chef::Log.debug("nimclient: checking version #{version_i} vs #{showres_i} to determine latest version")
          if version_i.to_i > showres_i.to_i
            showres_version = s_fileset.split(' ')[-1]
          end
        end
      end
      Chef::Log.debug("nimclient: checking #{a_fileset} version #{lpp_version} vs showres version #{showres_version}")
      # checking the current version versus lpp_source version
      if lpp_version == showres_version
        Chef::Log.debug("nimclient: #{a_fileset} is already to the #{resource} version")
      else
        filesets_return.push(a_fileset)
      end
    end
  end
  filesets_return
end

# check if a resource is already allocated to the client
def is_resource_allocated(resource, type)
  allocated = false
  standalone = shell_out("nimclient -ll #{node['hostname']}").stdout
  standalone.each_line do |standalone_l|
    standalone_a = standalone_l.split('=')
    type_s = standalone_a[0].to_s.strip
    resource_s = standalone_a[1].to_s.strip
    Chef::Log.debug("nimclient: compare |#{type_s}| vs |#{type}|, |#{resource_s}| vs |#{resource}|")
    if type_s == type
      if resource_s == resource
        allocated = true
        break
      end
    end
  end
  allocated
end
