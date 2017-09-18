#
# Copyright:: 2015-2016, Benoit Creau <benoit.creau@chmod666.org>
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

actions :update, :reset, :reset_all, :reset_all_with_reboot
default_action :update
attr_accessor :exists

attribute :name, name_attribute: true, kind_of: String
attribute :tunables, kind_of: Hash
attribute :set_default, kind_of: [TrueClass, FalseClass], default: false
