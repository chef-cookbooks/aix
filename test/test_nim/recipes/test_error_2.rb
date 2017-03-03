#
# Copyright:: 2016, Atos <jerome.hurstel@atos.net>
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

node.default['nim']['clients'] = { 'client_error' => { 'oslevel' => '7100-09' } }
node.default['nim']['lpp_sources']['7100-09-04-lpp_source'] = { 'Rstate' => 'ready for use', 'location' => '/tmp/img.source/7100-09-04-lpp_source/installp/ppc', 'alloc_count' => '0', 'server' => 'master' }

aix_nim 'Updating but failure' do
  lpp_source '7100-09-04-lpp_source'
  targets   'client_error'
  action    :update
end
