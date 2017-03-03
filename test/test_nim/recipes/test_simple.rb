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

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-09' }, 'client2' => { 'oslevel' => '7100-10' }, 'client3' => { 'oslevel' => '7100-08' } }
node.default['nim']['lpp_sources']['7100-09-04-lpp_source'] = { 'Rstate' => 'ready for use', 'location' => '/tmp/img.source/7100-09-04-lpp_source/installp/ppc', 'alloc_count' => '0', 'server' => 'master' }

aix_nim 'Updating 2 clients => SP 7100-09-04' do
  lpp_source  '7100-09-04-lpp_source'
  targets     'client1,client2'
  action      :update
end

aix_nim 'no updating (lpp not exist) => TL 7100-11' do
  lpp_source  '7100-11-lpp_source'
  targets     'client1,client2'
  action      :update
end
