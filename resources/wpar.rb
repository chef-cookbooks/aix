#
# Copyright 2016, Alain Dejoux <adejoux@djouxtech.net>
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

actions :create, :start, :stop, :sync, :delete
default_action :create
attr_accessor :exists

attribute :name, name_attribute: true, kind_of: String
attribute :hostname, kind_of: String
attribute :address, kind_of: String
attribute :interface, kind_of: String
attribute :rootvg, kind_of: [TrueClass, FalseClass], default: false
attribute :rootvg_disk, kind_of: String
attribute :wparvg, kind_of: String
attribute :backupimage, kind_of: String
attribute :cpu, kind_of: String
attribute :memory, kind_of: String
attribute :autostart, kind_of: [TrueClass, FalseClass], default: false
attribute :state, kind_of: String, default: nil
attribute :live_stream, kind_of: [TrueClass, FalseClass], default: false
