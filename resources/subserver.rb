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

actions :enable, :disable

attribute :servicename, name_attribute: true, kind_of: String
attribute :type, kind_of: String, equal_to: %w(dgram stream sunrpc_udp sunrpc_tcp)
attribute :protocol, kind_of: String, required: true, equal_to: %w(tcp udp tcp6 udp6)
attribute :wait, kind_of: String, default: 'nowait', equal_to: %w(wait nowait SRC)
attribute :user, kind_of: String, default: 'root', required: true
attribute :program, kind_of: String
attribute :args, kind_of: String

attr_accessor :enabled

default_action :enable

# TODO:
# * Validation method (if possible) to ensure that stream sockets are nowait only
# * Validation method (if possible) to ensure that if type is sunrpc_udp, that protocol is udp and same for tcp
