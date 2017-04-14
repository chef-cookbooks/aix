#
# Copyright 2015-2016, Benoit Creau <benoit.creau@chmod666.org>
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
# Amended by Ian Bellinfantie
# Contact ibellinfantie@sbm.com.sa
#
# just copied the etchosts and made the etcresolv
# uses the namerslv command instead of the namerslv command
#
# uses the options for IBM command namerslv
# does not cater for options.

actions :add, :delete, :delete_all, :change
default_action :add
attr_accessor :exists

attribute :name, name_attribute: true, kind_of: String		# type of /etc/resolv.conf entry e.g. domain, search, nameserver
attribute :address, kind_of: String						# Address in domain name or ip address , search option etc...
attribute :new_address, kind_of: String       # value to chnge to
