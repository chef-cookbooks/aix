#
# Author:: Laurent GAY for IBM (<lgay@us.ibm.com>)
# Cookbook Name:: aix
# test::  recipe for LVM
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
 
aix_volume_group 'datavg' do
    physical_volumes          ['hdisk1', 'hdisk2']
    action :create
end

aix_volume_group 'foovg' do
    physical_volumes          ['hdisk10']
    action :create
end

aix_logical_volume 'part1' do
    group 'datavg'
    size   512
    action :create
end

aix_logical_volume 'part2' do
    group 'datavg'
    size   1024
    copies 2
    action :create
end

aix_logical_volume 'part3' do
    group 'foovg'
    size   2048
    action :create
end

aix_filesystem '/lvm/folder1' do
    logical 'part1'
    size   '256M'
    action :create
end

aix_filesystem '/lvm/folder2' do
    logical 'part2'
    size   '1024'
    action :create
end

aix_filesystem '/lvm/folder3' do
    logical 'part2'
    size   '128M'
    action :create
end

aix_volume_group 'datavg' do
    physical_volumes          ['hdisk1', 'hdisk2', 'hdisk3']
    action :create
end

aix_logical_volume 'part1' do
    group 'datavg'
    size   2048
    action :create
end

aix_filesystem '/lvm/folder2' do
    logical 'part2'
    size   '512'
    action :create
end

aix_filesystem '/lvm/folder2' do
    action :mount
end

aix_filesystem '/lvm/folder2' do
    action :defragfs
end
