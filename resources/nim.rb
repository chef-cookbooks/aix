# Author:: Jérôme Hurstel (<jerome.hurstel@atos.ne>) & Laurent Gay (<laurent.gay@atos.net>)
# Cookbook Name:: aix
# Provider:: nim
#
# Copyright:: 2016, Atos
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

property :type, String
property :targets, String
property :lpp_source, String
property :location, String

# nim reminder
# nim -o cust -a lpp_source=<lpp_source> <targets>
# nim -o define -t <type> -a server=<server> -a location=<location> <lpp_source>
# nim -o remove -t <type> <lpp_source>

load_current_value do

end
	
action :cust do
  
  nim_s = 'nim -o cust'

  # getting lpp_source
  nim_s = nim_s << ' -a lpp_source=' << lpp_source
  
  # getting targets
  nim_s = nim_s << ' ' << targets

  # removing any efixes
#  aix_fixes 'remvoving_efixes' do
#	fixes ['all']
#	action :remove
  #end

  # committing filesets in APPLIED state
  # no guard needed here
  #execute 'commit' do
  #  command 'installp -c all'
  #end

  # running command
  execute "#{nim_s}" do
	action :run		# replace by :run action
  end

end

action :define do
  
  nim_s = 'nim -o define -a server=master'

  # getting type
  nim_s = nim_s << ' -t type=' << type
  
  # getting location
  nim_s = nim_s << ' -a location=' << location

  # getting lpp_source
  nim_s = nim_s << ' ' << lpp_source

  # running command
  execute "#{nim_s}" do
	action :run		# replace by :run action
  end

end

action :remove do
  
  nim_s = 'nim -o remove'

  # getting type
  nim_s = nim_s << ' -t type=' << type
  
  # getting lpp_source
  nim_s = nim_s << ' ' << lpp_source

  # running command
  execute "#{nim_s}" do
	action :run		# replace by :run action
  end

end
