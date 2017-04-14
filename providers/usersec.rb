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


use_inline_resources

# support whyrun
def whyrun_supported?
  true
end

# load current resource name to detremine type of resolv.conf change
def load_current_resource
  @current_resource = Chef::Resource::AixUsersec.new(@new_resource.name)
  # entry types could be domain, search, nameserver, options
  @current_resource.exists = false
  # set command for all entries for /etc/security/limits
    user_sec = shell_out("for attr in umask pwdwarntime loginretries histexpire histsize minage maxage maxexpired minalpha minother minlen mindiff maxrepeats ; do lssec -c -f /etc/security/user -s default -a $attr ; done | xargs | sed \'s/default://g\' | sed \'s/\\#name://g\' | perl -pe \'chomp\'")
    if !user_sec.error?
    user_sec_array = user_sec.stdout.split(' ')
    Chef::Log.debug('usersec: resource exists')
    @current_resource.exists = true
    else
    Chef::Log.debug('usersec: resource does not exists')
    end

      # If resource exists ,  load values into a hash
        if @current_resource.exists
           Chef::Log.debug('usersec: resource exists loading attributes')
           @current_resource.name(@new_resource.name)
           Chef::Log.debug("usersec: current resource name:  #{@current_resource.name}")

           @current_resource.umask(user_sec_array[1])
           @current_resource.pwdwarntime(user_sec_array[3])
           @current_resource.loginretries(user_sec_array[5])
           @current_resource.histexpire(user_sec_array[7])
           @current_resource.histsize(user_sec_array[9])
           @current_resource.minage(user_sec_array[11])
           @current_resource.maxage(user_sec_array[13])
           @current_resource.maxexpired(user_sec_array[15])
           @current_resource.minalpha(user_sec_array[17])
           @current_resource.minother(user_sec_array[19])
           @current_resource.minlen(user_sec_array[21])
           @current_resource.mindiff(user_sec_array[23])
           @current_resource.maxrepeats(user_sec_array[25])

           Chef::Log.debug("user_sec: current resource umask: #{user_sec_array[1]}")
           Chef::Log.debug("user_sec: current resource pwdwarntime: #{user_sec_array[3]}")
           Chef::Log.debug("user_sec: current resource loginretries: #{user_sec_array[5]}")
           Chef::Log.debug("user_sec: current resource histexpire: #{user_sec_array[7]}")
           Chef::Log.debug("user_sec: current resource histsize: #{user_sec_array[9]}")
           Chef::Log.debug("user_sec: current resource minage: #{user_sec_array[11]}")
           Chef::Log.debug("user_sec: current resource maxage: #{user_sec_array[13]}")
           Chef::Log.debug("user_sec: current resource maxexpired: #{user_sec_array[15]}")
           Chef::Log.debug("user_sec: current resource minalpha: #{user_sec_array[17]}")
           Chef::Log.debug("user_sec: current resource minother: #{user_sec_array[19]}")
           Chef::Log.debug("user_sec: current resource minlen: #{user_sec_array[21]}")
           Chef::Log.debug("user_sec: current resource mindiff: #{user_sec_array[23]}")
           Chef::Log.debug("user_sec: current resource maxrepeats: #{user_sec_array[25]}")

                  if @new_resource.umask.nil?
                     @new_resource.umask(@current_resource.umask)
                  end
                  if @new_resource.pwdwarntime.nil?
                     @new_resource.pwdwarntime(@current_resource.pwdwarntime)
                  end
                  if @new_resource.loginretries.nil?
                     @new_resource.loginretries(@current_resource.loginretries)
                  end
                  if @new_resource.histexpire.nil?
                     @new_resource.histexpire(@current_resource.histexpire)
                  end
                  if @new_resource.histsize.nil?
                     @new_resource.histsize(@current_resource.histsize)
                  end
                  if @new_resource.minage.nil?
                     @new_resource.minage(@current_resource.minage)
                  end
                  if @new_resource.maxage.nil?
                     @new_resource.maxage(@current_resource.maxage)
                  end
                  if @new_resource.maxexpired.nil?
                     @new_resource.maxexpired(@current_resource.maxexpired)
                  end
                  if @new_resource.minalpha.nil?
                     @new_resource.minalpha(@current_resource.minalpha)
                  end
                  if @new_resource.minother.nil?
                     @new_resource.minother(@current_resource.minother)
                  end
                  if @new_resource.minlen.nil?
                     @new_resource.minlen(@current_resource.minlen)
                  end
                  if @new_resource.mindiff.nil?
                     @new_resource.mindiff(@current_resource.mindiff)
                  end
                  if @new_resource.maxrepeats.nil?
                     @new_resource.maxrepeats(@current_resource.maxrepeats)
                  end
          end
end



#
action :change do
  if @current_resource.exists
    change = false
      # check if we have changed values for any attribute

      if @new_resource.umask != @current_resource.umask ||  @new_resource.pwdwarntime != @current_resource.pwdwarntime || @new_resource.loginretries != @current_resource.loginretries || @new_resource.histexpire != @current_resource.histexpire || @new_resource.histsize != @current_resource.histsize || @new_resource.minage != @current_resource.minage || @new_resource.maxage != @current_resource.maxage || @new_resource.maxexpired != @current_resource.maxexpired || @new_resource.minalpha != @current_resource.minalpha || @new_resource.minother != @current_resource.minother || @new_resource.minlen != @current_resource.minlen || @new_resource.mindiff != @current_resource.mindiff || @new_resource.maxrepeats != @current_resource.maxrepeats
          change = true

              if change
    usersec_change_s = "chsec -f /etc/security/user -s default -a umask=#{@new_resource.umask} ; chsec -f /etc/security/user -s default -a pwdwarntime=#{@new_resource.pwdwarntime} ;  chsec -f /etc/security/user -s default -a loginretries=#{@new_resource.loginretries} ;  chsec -f /etc/security/user -s default -a histexpire=#{@new_resource.histexpire};  chsec -f /etc/security/user -s default -a histsize=#{@new_resource.histsize} ; chsec -f /etc/security/user -s default -a minage=#{@new_resource.minage} ; chsec -f /etc/security/user -s default -a maxage=#{@new_resource.maxage} ; chsec -f /etc/security/user -s default -a maxexpired=#{@new_resource.maxexpired} ; chsec -f /etc/security/user -s default -a minalpha=#{@new_resource.minalpha} ; chsec -f /etc/security/user -s default -a minother=#{@new_resource.minother} ; chsec -f /etc/security/user -s default -a minlen=#{@new_resource.minlen} ; chsec -f /etc/security/user -s default -a mindiff=#{@new_resource.mindiff} ;  chsec -f /etc/security/user -s default -a maxrepeats=#{@new_resource.maxrepeats} "
          converge_by("usersec: change #{@new_resource.name} in /etc/security/user file") do
          Chef::Log.debug("usersec: running #{usersec_change_s}")
          shell_out!(usersec_change_s)
                  end
              end
    end
  end
end
