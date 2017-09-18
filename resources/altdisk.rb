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

actions :create, :cleanup, :rename, :wakeup, :sleep, :customize
default_action :create
attr_accessor :exists

# value can be an hdisk* name, or a given size
# if you are searching for disk to perform an alternate disk copy
# type are:
#  - size : find a free disk with a size bigger or equal to value
#  - name : find a free disk with the same name as value
#  - auto : find the first free disk with a size bigger or equal to the current rootvg size
attribute :value, kind_of: String
attribute :type, kind_of: Symbol, equal_to: [:size, :name, :auto]
attribute :altdisk_name, kind_of: String
attribute :new_altdisk_name, kind_of: String
attribute :change_bootlist, kind_of: [TrueClass, FalseClass], default: false
attribute :image_location, kind_of: String
attribute :reset_devices, kind_of: [TrueClass, FalseClass], default: false
attribute :remain_nimclient, kind_of: [TrueClass, FalseClass], default: false
