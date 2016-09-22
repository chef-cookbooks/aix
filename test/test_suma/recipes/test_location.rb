#
# Copyright 2016, Atos <jerome.hurstel@atos.net>
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

node.default['nim'] = { 'clients' => { 'client1' => { 'oslevel' => '7100-02-01' } },
                        'lpp_sources' => { 'my_beautifull_lpp-source' => { 'location' => '/usr/sys/inst.images/beautifull' }, '7100-02-03-lpp_source' => { 'location' => '/usr/sys/inst.images/7100-02-03-lpp_source' } } }

aix_suma '21. Existing directory (absolute path)' do
  oslevel	'7100-02-02'
  location  '/tmp/img.source/21'
  targets   'client1'
  action    :download
end

aix_suma '23. Default property location (/usr/sys/inst.images)' do
  oslevel	'7100-02-02'
  # location  '/usr/sys/inst.images'
  targets   'client1'
  action    :download
end

aix_suma '24. Empty property location (/usr/sys/inst.images)' do
  oslevel   '7100-02-03'
  location  ''
  targets   'client1'
  action    :download
end

aix_suma '27. Provide existing lpp source as location' do
  oslevel   '7100-02-02'
  location  'my_beautifull_lpp-source'
  targets   'client1'
  action    :download
end
