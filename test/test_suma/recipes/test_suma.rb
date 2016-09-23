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

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma '45. error no fixes 0500-035 (Preview only)' do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/45/'
  targets   'client1'
  action    :download
end

aix_suma '46. nothing to download (Preview only)' do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/46/'
  targets   'client1'
  action    :download
end

aix_suma '47. failed fixes (Preview + Download)' do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/47/'
  targets   'client1'
  action    :download
end

aix_suma '48. lpp source exists (Preview + Download)' do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/48/'
  targets   'client1'
  action    :download
end

aix_suma '49. lpp source absent (Preview + Download + Define)' do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/49/'
  targets   'client1'
  action    :download
end
