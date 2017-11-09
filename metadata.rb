#
# Copyright:: 2014-2016, Chef Software, Inc.
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

name             'aix'
maintainer       'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license          'Apache-2.0'
description      'Custom resources useful for AIX systems'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.2.1'
source_url       'https://github.com/chef-cookbooks/aix'
issues_url       'https://github.com/chef-cookbooks/aix/issues'

supports 'aix', '>= 6.1'

chef_version '>= 12.7'
