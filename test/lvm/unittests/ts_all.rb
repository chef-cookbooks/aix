#
# Author:: Laurent GAY for IBM (<lgay@us.ibm.com>)
# Cookbook Name:: aix
# test::  all unit tests laucher
#
# Copyright:: 2016, IBM
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

require 'test/unit'
require_relative 'tc_aix_storage_objects.rb' if (/aix/ =~ RUBY_PLATFORM) !=nil
require_relative 'tc_storage_objects.rb'
require_relative 'tc_objects_vg'
require_relative 'tc_objects_lv'
require_relative 'tc_objects_fs'