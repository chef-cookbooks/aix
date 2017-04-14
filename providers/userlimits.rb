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
# there should only be one line in /etc/netsvc.conf
# so either add or delete the line
#

use_inline_resources

# support whyrun
def whyrun_supported?
  true
end

# load current resource name to detremine type of resolv.conf change
def load_current_resource
  @current_resource = Chef::Resource::AixUserlimits.new(@new_resource.name)
  # entry types could be domain, search, nameserver, options
  @current_resource.exists = false
  # set command for all entries for /etc/security/limits
    user_limits = shell_out("cat /etc/security/limits | grep -v \\* | grep -wp default | grep -v default | sed \'\/^\\s*\$\/d\' | xargs | sed \'s\/=\/:\/g\' | tr -s \' \' \':\' | perl -pe \'chomp\'")
    if !user_limits.error?
    user_limits_array = user_limits.stdout.split(':')
    Chef::Log.debug('userlimits: resource exists')
    @current_resource.exists = true
    else
    Chef::Log.debug('userlimits: resource does not exists')
    end

      # If resource exists ,  load values into a hash
        if @current_resource.exists
           Chef::Log.debug('userlimits: resource exists loading attributes')
           @current_resource.name(@new_resource.name)
           Chef::Log.debug("userlimits: current resource name:  #{@current_resource.name}")

           @current_resource.fsize(user_limits_array[1])
           @current_resource.core(user_limits_array[3])
           @current_resource.cpu(user_limits_array[5])
           @current_resource.data(user_limits_array[7])
           @current_resource.rss(user_limits_array[9])
           @current_resource.stack(user_limits_array[11])
           @current_resource.nofiles(user_limits_array[13])
           Chef::Log.debug("userlimits: current resource fsize: #{user_limits_array[1]}")
             Chef::Log.debug("userlimits: current resource core: #{user_limits_array[3]}")
              Chef::Log.debug("userlimits: current resource cpu: #{user_limits_array[5]}")
               Chef::Log.debug("userlimits: current resource data: #{user_limits_array[7]}")
                Chef::Log.debug("userlimits: current resource rss: #{user_limits_array[9]}")
                 Chef::Log.debug("userlimits: current resource stack: #{user_limits_array[11]}")
                  Chef::Log.debug("userlimits: current resource nofiles: #{user_limits_array[13]}")


                  if @new_resource.fsize.nil?
                     @new_resource.fsize(@current_resource.fsize)
                  end
                  if @new_resource.core.nil?
                     @new_resource.core(@current_resource.core)
                  end
                  if @new_resource.cpu.nil?
                     @new_resource.cpu(@current_resource.cpu)
                  end
                  if @new_resource.data.nil?
                     @new_resource.data(@current_resource.data)
                  end
                  if @new_resource.rss.nil?
                     @new_resource.rss(@current_resource.rss)
                  end
                  if @new_resource.stack.nil?
                     @new_resource.stack(@current_resource.stack)
                  end
                  if @new_resource.nofiles.nil?
                     @new_resource.nofiles(@current_resource.nofiles)
                  end
          end
end



# change the default settings for user limits -- using default instaed of #{@new_resource.name} to ensure only
# the default settings are changed.
action :change do

      if @new_resource.fsize != @current_resource.fsize ||  @new_resource.core != @current_resource.core || @new_resource.cpu != @current_resource.cpu || @new_resource.data != @current_resource.data || @new_resource.rss != @current_resource.rss || @new_resource.stack != @current_resource.stack || @new_resource.nofiles != @current_resource.nofiles
          change = true


              nfs = @new_resource.fsize
              nco = @new_resource.core
              ncp = @new_resource.cpu
              nda = @new_resource.data
              nrs = @new_resource.rss
              nst = @new_resource.stack
              nno = @new_resource.nofiles

              cfs = @current_resource.fsize
              cco = @current_resource.core
              ccp = @current_resource.cpu
              cda = @current_resource.data
              crs = @current_resource.rss
              cst = @current_resource.stack
              cno = @current_resource.nofiles

              if change
    userlimits_change_s = "cat /etc/security/limits|sed -n \'1h;1\!H;\${x;/default:/ s/fsize = #{cfs}/fsize = #{nfs}/g;p;}\'|sed -n \'1h;1\!H;\${x;/default:/ s/core = #{cco}/core = #{nco}/g;p;}\'|sed -n \'1h;1\!H;\${x;/default:/ s/cpu = #{ccp}/cpu = #{ncp}/g;p;}\'|sed -n \'1h;1\!H;\${x;/default:/ s/data = #{cda}/data = #{nda}/g;p;}\'|sed -n \'1h;1\!H;\${x;/default:/ s/rss = #{crs}/rss = #{nrs}/g;p;}\'|sed -n \'1h;1\!H;\${x;/default:/ s/stack = #{cst}/stack = #{nst}/g;p;}\'|sed -n \'1h;1\!H;\${x;/default:/ s/nofiles = #{cno}/nofiles = #{nno}/g;p;}\' >/etc/security/limits"
          converge_by("userlimits: change #{@new_resource.name} in /etc/security/limits file") do
          Chef::Log.debug("userlimits: running #{userlimits_change_s}")
          shell_out!(userlimits_change_s)
                  end
              else
                change = false
              end
    end
  end
