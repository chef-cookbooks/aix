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
# makes changes for the deafult or a particular username

actions :change
default_action :change
attr_accessor :exists

attribute :name, name_attribute: true, kind_of: String		 # will always be default... leaving users to specific application builds
attribute :fsize, kind_of: String						               # attributes for user limits
attribute :core, kind_of: String
attribute :cpu, kind_of: String
attribute :data, kind_of: String
attribute :rss, kind_of: String
attribute :stack, kind_of: String
attribute :nofiles, kind_of: String
