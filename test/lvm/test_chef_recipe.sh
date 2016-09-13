#!/bin/sh
#
# Author:: Laurent GAY for IBM (<lgay@us.ibm.com>)
# Cookbook Name:: aix
# Test::  script launcher
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

export PATH=$PATH:/opt/chef/bin
run_option="$1"

current_dir=$PWD
if [ ! -d "$current_dir/aix/test/lvm/recipes" ]
then
    echo "*** tests for cookbook aix not found! ***"
    exit 1
fi

cd $current_dir

echo "--------- Initial LVM for test -----------"
umount /lvm/folder2 2>/dev/null
varyoffvg datavg 2>/dev/null
exportvg datavg 2>/dev/null
rm -rf /lvm 2>/dev/null
disks=$(echo $(lspv | grep 'None' | sed 's|\(hdisk[0-9]*\).*|\1|g'))
if [ "$disks" != "hdisk1 hdisk2 hdisk3 hdisk4" ]
then
	lspv
	echo "*** Bad initial disk status ****"
	exit 1
fi

if [ "$run_option" != "NO-UNIT" ]
then
	echo "--------- Run unittest for LVM -----------"
	/opt/chef/embedded/bin/ruby $current_dir/aix/test/lvm/unittests/ts_all.rb
	if [ $? -ne 0 ]
	then
		echo "*** Unittest failure ****"
		exit 1
	fi
fi

echo "--------- Prepare tests cookbook ---------"
rm -rf $current_dir/aixtest
mkdir -p $current_dir/aixtest
cp -r $current_dir/aix/test/lvm/recipes $current_dir/aixtest/recipes
echo "name             'aixtest'\ndepends   'aix'\nsupports 'aix', '>= 6.1'\n" > $current_dir/aixtest/metadata.rb
echo "cookbook_path \"$current_dir\"" > $current_dir/solo.rb
echo "{\n\"run_list\": [ \"recipe[aixtest]\" ]\n}\n" > $current_dir/firstrun.json

echo "--------- Run test cookbool --------------"
chef-solo -c $current_dir/solo.rb -j $current_dir/firstrun.json
if [ $? -ne 0 ]
then
	echo "*** Cookbook failure ****"
	exit 1
fi

echo "--------- Check LVM ----------------------"
result=0
disk_datavg=$(echo $(lspv | grep 'datavg' | sed 's|\(hdisk[0-9]*\).*|\1|g'))
lv_datavg=$(echo $(lspv | grep 'datavg' | sed 's|\(hdisk[0-9]*\).*|\1|g'))
sizes_part1=$(lsvg -l datavg | grep 'part1' | sed 's|.*jfs2[ \t]*\([0-9]*\)[ \t]*\([0-9]*\)[ \t]*\([0-9]*\).*|\1 \2 \3|g')
sizes_part2=$(lsvg -l datavg | grep 'part2' | sed 's|.*jfs2[ \t]*\([0-9]*\)[ \t]*\([0-9]*\)[ \t]*\([0-9]*\).*|\1 \2 \3|g')
if [ "$disk_datavg" != "hdisk1 hdisk2 hdisk3" ]
then
	echo "disk=$disk_datavg"
	echo "*** Bad PV include in datavg ****"
	result=1
fi
if [ "$sizes_part1" != "512 512 1" ]
then
	echo "sizes part1=$sizes_part1"
	echo "*** Bad sizes (LPs,PPs,PVs) for LV part1 ****"
	result=1
fi
if [ "$sizes_part2" != "64 128 2" ]
then
	echo "sizes part2=$sizes_part2"
	echo "*** Bad sizes (LPs,PPs,PVs) for LV part2 ****"
	result=1
fi

if [ $result -eq 0 ] 
then
	echo "====== SUCCESS ====== "
else
	lsvg datavg
	lsvg -p datavg
	lsvg -l datavg
fi

echo "--------- Clean --------------------------"
rm -rf $current_dir/aixtest
rm -rf $current_dir/solo.rb $current_dir/firstrun.json

