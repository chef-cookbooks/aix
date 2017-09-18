#
# Copyright:: 2016, Alain Dejoux <adejoux@djouxtech.net>
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

module WPARHelper
  def require_wpar_gem
    # require attribute specified gems
    gem 'aix-wpar', node['aix-wpar']['version']
    require 'wpars'
    Chef::Log.debug("Node had aix-wpar #{node['aix-wpar']['version']} installed. No need to install gems.")
  rescue LoadError
    Chef::Log.debug('Did not find aix-wpar gem of the specified versions installed. Installing now')

    chef_gem 'aix-wpar' do
      action :install
      version node['aix-wpar']['version']
      compile_time true if Chef::Resource::ChefGem.method_defined?(:compile_time)
    end

    require 'wpars'
  end
end
