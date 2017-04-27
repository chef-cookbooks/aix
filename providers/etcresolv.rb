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
# Amended by Ian Bellinfantie
# Contact ibellinfantie@sbm.com.sa
#
# just copied the etchosts and made the etcresolv
# uses the namerslv command instead of the namerslv command
#

use_inline_resources

# support whyrun
def whyrun_supported?
  true
end

# load current resource name to detremine type of resolv.conf change
def load_current_resource
  @current_resource = Chef::Resource::AixEtcresolv.new(@new_resource.name)
  # entry types could be domain, search, nameserver, options
  @current_resource.exists = false
  # set command for all entries for /etc/resolv.conf
  namerslv = shell_out("namerslv -s | grep  #{@new_resource.address}")
  if !namerslv.error?
    namerslv_array = namerslv.stdout.split(' ')
    Chef::Log.debug('etcresolv: resource exists')
    @current_resource.exists = true
  else
    Chef::Log.debug('etcresolv: resource does not exists')
  end

  # If resource exists ,  load values into a hash
  if @current_resource.exists
     Chef::Log.debug('etcresolv: resource exists loading attributes')
     @current_resource.name(namerslv_array[0])
     Chef::Log.debug("etcresolv: current resource name: #{namerslv_array[0]}")
     @current_resource.address(namerslv_array[1])
     Chef::Log.debug("etcresolv: current resource address: #{namerslv_array[1]}")
     puts "#{namerslv_array[0]} #{namerslv_array[1]}"
  end
end


# add
action :add do
  unless @current_resource.exists
    # add entry if it exists
    if @new_resource.name =~ /nameserver/
     #An ip address  has been given
     namerslv_add_s = "namerslv -a -i #{@new_resource.address} "
    elsif @new_resource.name =~ /search/
     # A search domain_name has been given
     namerslv_add_s = "namerslv -a -S #{@new_resource.address} "
    elsif @new_resource.name =~ /domain/
     # A domain name has been given
     namerslv_add_s = "namerslv -a -D #{@new_resource.address} "
    else
     puts " Don't know what has been given"
    end
   converge_by("namerslv: add #{@new_resource.address} in /etc/resolv.conf file") do
   Chef::Log.debug("etcresolv: running #{namerslv_add_s}")
   shell_out!(namerslv_add_s)
   end
  end
end

# delete
action :delete do
  if @current_resource.exists
     # delete entry if it exists
     if @new_resource.name =~ /nameserver/
     #An ip address  has been given for nameserver
     namerslv_del_s = "namerslv -d -i #{@new_resource.address} "
     elsif @new_resource.name =~ /domain/
     # A domain name has been given
     namerslv_del_s = "namerslv -d -n "
     else
     puts " Option not supported"
     end
    converge_by("namerslv: delete #{@new_resource.address} in /etc/resolv.conf file") do
    Chef::Log.debug("etcresolv: running #{namerslv_del_s}")
    shell_out!(namerslv_del_s)
    end
  end
end

# change
action :change do
  if @current_resource.exists
  # determine which type to change
    if @new_resource.name =~ /nameserver/
    #An ip address  has been given for nameserver
    namerslv_change_s = "namerslv -d -i #{@new_resource.address} ; namerslv -a -i #{@new_resource.new_address}"
    elsif @new_resource.name =~ /domain/
    # A domain name has been given
    namerslv_change_s = "namerslv -d -n ; namerslv -a -D #{@new_resource.new_address}"
    else
    puts " Option not supported"
    end
   converge_by("namerslv: delete #{@new_resource.address} in /etc/resolv.conf file") do
   Chef::Log.debug("etcresolv: running #{namerslv_change_s}")
   shell_out!(namerslv_change_s)
   end
  end
end

# delete_all
action :delete_all do
  if @current_resource.exists
  namerslv_del_all_s = "namerslv -X"
    converge_by('etcresolv: removing all entries') do
    Chef::Log.debug("etcresolv: running #{namerslv_del_all_s}")
    shell_out!(namerslv_del_all_s)
    end
  end
end
