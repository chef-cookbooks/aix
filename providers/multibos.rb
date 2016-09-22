#
# Copyright 2015-2016, Benoit Creau <benoit.creau@chmod666.org>
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

# load current resource
def load_current_resource
  @current_resource = Chef::Resource::AixMultibos.new(@new_resource.name)
  @current_resource.exists = false

  # if bos_hd5 and hd5 exists there is a standby bos
  so = shell_out("lsvg -l rootvg | grep -iEw \"bos_hd5|hd5\" | wc -l | awk '{print $1}'")
  Chef::Log.debug('multibos: searching for bos')
  Chef::Log.debug(so.stdout)
  # if there are two lines there is a bos
  Chef::Log.debug("multibos: comparing #{so.stdout.chomp} with 2")
  if so.stdout.chomp == '2'
    Chef::Log.debug('multibos: there is a bos')
    @current_resource.exists = true
  else
    Chef::Log.debug('multibos: there is no bos')
    @current_resource.exists = false
  end
end

# create a multibos
action :create do
  # if there is no bos we can create one
  unless @current_resource.exists
    converge_by('multibos: creating standby multibos') do
      string_shell_out = 'multibos -Xs'
      # if bootlist is set to true do not change the bootlist (-t option)
      string_shell_out = "#{string_shell_out}t" if @new_resource.bootlist
      unless @new_resource.update_device.nil?
        string_shell_out = string_shell_out << 'a -l ' << @new_resource.update_device
      end
      Chef::Log.debug("multibos: creating standby bos with command #{string_shell_out}")
      so = shell_out(string_shell_out, timeout: 7200)
      if so.exitstatus != 0 || !so.stderr.empty?
        raise('multibos: error creating standby bos')
      end
    end
  end
end

# removing a multibos
action :remove do
  # we can remove a multibos only if this one exists
  if @current_resource.exists
    converge_by('multibos: removing standby multibos') do
      Chef::Log.debug('multibos: removing standby multibos with command multibos -RX')
      so = shell_out('multibos -RX')
      if so.exitstatus != 0 || !so.stderr.empty?
        raise('multibos: error removing multibos')
      end
    end
  end
end

# updating a multibos
action :update do
  # we can update a multibos only if this one exists
  if @current_resource.exists
    converge_by('mutlibos: updating standby multibos') do
      string_shell_out = 'multibos -ac -l ' << @new_resource.update_device
      Chef::Log.debug("multibos: updating standby multibos with command #{string_shell_out}")
      so = shell_out(string_shell_out, timeout: 7200)
      if so.exitstatus != 0 || !so.stderr.empty?
        raise('multibos: error updating multibos')
      end
    end
  end
end

# mount a multibos
action :mount do
  # we can mount a multibos only if this one exists
  if @current_resource.exists
    # check if multibos is already mounted
    # is the standby bos prefixed by bos or not
    lvs = []
    blv = shell_out('bootinfo -v')
    Chef::Log.debug("multibos: blv is #{blv.stdout}")
    if blv.stdout.include? 'bos'
      Chef::Log.debug('multibos: multibos is not prefixed by bos')
      lvs = %w(hd4 hd2 hd9var hd10opt)
    else
      Chef::Log.debug('multibos: multibos is prefixed by bos')
      lvs = %w(bos_hd4 bos_hd2 bos_hd9var bos_hd10opt)
    end
    mounted = true
    lvs.each do |lv|
      is_mounted = shell_out("lsvg -l rootvg | awk '$1 == \"#{lv}\" {print $6}'")
      Chef::Log.debug("multibos: checking #{lv} is closed (#{is_mounted.stdout.chomp})")
      if is_mounted.stdout.chomp == 'closed/syncd'
        Chef::Log.debug("multibos: #{lv} is not mounted")
        mounted = false
      end
    end
    # we need to run multibos -m only if there is one lv not mounted
    if !mounted
      Chef::Log.debug('multibos: mounting multibos')
      converge_by('multibos: mounting standby bos') do
        stby_bos = shell_out('multibos -m')
        if stby_bos.exitstatus != 0 || !stby_bos.stderr.empty?
          Chef::Log.debug('multibos: error while multibos -m')
          raise('multibos: error while multibos -m')
        end
      end
    else
      Chef::Log.debug('multibos: bos already mounted')
    end
  end
end

# umount a multibos
action :umount do
  # we can mount a multibos only if this one exists
  if @current_resource.exists
    # check if multibos is already mounted
    # is the standby bos prefixed by bos or not
    lvs = []
    blv = shell_out('bootinfo -v')
    Chef::Log.debug("multibos: blv is #{blv.stdout}")
    if blv.stdout.include? 'bos'
      Chef::Log.debug('multibos: multibos is not prefixed by bos')
      lvs = %w(hd4 hd2 hd9var hd10opt)
    else
      Chef::Log.debug('multibos: multibos is prefixed by bos')
      lvs = %w(bos_hd4 bos_hd2 bos_hd9var bos_hd10opt)
    end
    mounted = false
    lvs.each do |lv|
      is_mounted = shell_out("lsvg -l rootvg | awk '$1 == \"#{lv}\" {print $6}'")
      Chef::Log.debug("multibos: checking #{lv} is open (#{is_mounted.stdout.chomp})")
      if is_mounted.stdout.chomp == 'open/syncd'
        Chef::Log.debug("multibos: #{lv} is not mounted")
        mounted = true
      end
    end
    # we need to run multibos -u only if there is one lv mounted
    if mounted
      Chef::Log.debug('multibos: umounting multibos')
      converge_by('multibos: umounting standby bos') do
        stby_bos = shell_out('multibos -u')
        if stby_bos.exitstatus != 0 || !stby_bos.stderr.empty?
          Chef::Log.debug('multibos: error while multibos -m')
          raise('multibos: error while multibos -u')
        end
      end
    else
      Chef::Log.debug('multibos: bos already umounted')
    end
  end
end
