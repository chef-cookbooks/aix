#
# Author:: Laurent GAY for IBM (<lgay@us.ibm.com>)
# Cookbook Name:: aix
# test:: unit test storage objects on AIX machine
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

require "test/unit"

require_relative "../../../libraries/storage_objects"
require_relative "mock"

class TestAIXStorage_PV < Test::Unit::TestCase
  def setup
    print("\n")
  end

  def test_01_exists
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk1")
    assert_equal(true, @stobj.exist?)
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk10")
    assert_equal(false, @stobj.exist?)
  end

  def test_02_get_vgname
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk10")
    assert_equal(nil, @stobj.get_vgname)
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk0")
    assert_equal('rootvg', @stobj.get_vgname)
  end

  def test_03_get_size
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk0")
    assert_equal(16384, @stobj.get_size)
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk1")
    assert_equal(4096, @stobj.get_size)
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk2")
    assert_equal(4096, @stobj.get_size)
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk3")
    assert_equal(4096, @stobj.get_size)
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk4")
    assert_equal(4096, @stobj.get_size)
    @stobj = AIXLVM::StObjPV.new(AIXLVM::System.new(),"hdisk5")
    assert_equal(0, @stobj.get_size)
  end
end

class TestAIXStorage_VG < Test::Unit::TestCase
  def setup
    print("\n")
    system("varyoffvg othervg 2>/dev/null")
    system("exportvg othervg 2>/dev/null")
    system("varyoffvg datavg 2>/dev/null")
    system("exportvg datavg 2>/dev/null")
    system("mkvg -y datavg -S -f hdisk1 2>/dev/null")
    system("chvg -h y datavg 2>/dev/null")
    system("extendvg -f datavg hdisk2 2>/dev/null")
  end

  def teardown
    system("varyoffvg datavg 2>/dev/null")
    system("exportvg datavg 2>/dev/null")
  end

  def test_01_exists
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal(true, @stobj.exist?)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal(false, @stobj.exist?)
  end

  def test_02_get_ppsize
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal(4, @stobj.get_ppsize)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal(nil, @stobj.get_ppsize)
  end

  def test_03_get_pv_list
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal([], @stobj.get_pv_list)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal(['hdisk1','hdisk2'], @stobj.get_pv_list)
  end

  def test_04_hot_spare
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal(true, @stobj.hot_spare?)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal(nil, @stobj.hot_spare?)
  end

  def test_05_get_totalpp
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal(2012, @stobj.get_totalpp)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal(nil, @stobj.get_totalpp)
  end

  def test_06_get_freepp
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal(2012, @stobj.get_freepp)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal(nil, @stobj.get_freepp)
  end

  def test_07_get_mirrorpool
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal(nil, @stobj.get_mirrorpool)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal('', @stobj.get_mirrorpool)
  end

  def test_08_get_nbpv
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    assert_equal(nil, @stobj.get_nbpv)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"rootvg")
    assert_equal(1, @stobj.get_nbpv)
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    assert_equal(2, @stobj.get_nbpv)
  end

  def test_08_create
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"othervg")
    @stobj.create('hdisk4','mymirror')
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.create('hdisk10', nil)
    }
    assert_equal('system error:0516-306 mkvg: Unable to find physical volume hdisk10 in the Device', exception.message[0,80])
  end

  def test_09_modify
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    @stobj.modify('y')
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.modify('n')
    }
    assert_equal('system error:0516-306 getlvodm: Unable to find volume group foovg in the Device', exception.message[0,79])
  end

  def test_10_add_pv
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    @stobj.add_pv('hdisk3', 'mymirror')
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.add_pv('hdisk2', nil)
    }
    assert_equal('system error:0516-306 extendvg: Unable to find volume group foovg in the Device', exception.message[0,79])
  end

  def test_11_delete_pv
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"datavg")
    @stobj.delete_pv('hdisk2')
    @stobj = AIXLVM::StObjVG.new(AIXLVM::System.new(),"foovg")
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.delete_pv('hdisk3')
    }
    assert_equal('system error:0516-306 getlvodm: Unable to find volume group foovg in the Device', exception.message[0,79])
  end
end

class TestAIXStorage_LV < Test::Unit::TestCase
  def setup
    print("\n")
    system("varyoffvg datavg 2>/dev/null")
    system("exportvg datavg 2>/dev/null")
    system("mkvg -y datavg -S -s 4 -f hdisk1 2>/dev/null")
    system("extendvg -f datavg hdisk2 2>/dev/null")
    system("mklv -t jfs2 -y part1 datavg 20 2>/dev/null")
  end

  def teardown
    system("varyoffvg datavg 2>/dev/null")
    system("exportvg datavg 2>/dev/null")
  end

  def test_01_exists
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'hd1')
    assert_equal(true, @stobj.exist?)
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'hd100')
    assert_equal(false, @stobj.exist?)
  end

  def test_02_get_vg
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'hd1')
    assert_equal('rootvg', @stobj.get_vg)
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'hd100')
    assert_equal(nil, @stobj.get_vg)
  end

  def test_03_get_nbpp
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'hd2')
    assert_equal(229, @stobj.get_nbpp)
    assert_equal(32, @stobj.get_ppsize)
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'hd100')
    assert_equal(nil, @stobj.get_nbpp)
    assert_equal(nil, @stobj.get_ppsize)
  end

  def test_04_get_mount
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'hd1')
    assert_equal("/home", @stobj.get_mount)
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'part20')
    assert_equal(nil, @stobj.get_nbpp)
  end

  def test_05_create
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'part2')
    @stobj.create('datavg',10, 2)
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'part3')
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.create('foovg', 20, 1)
    }
    assert_equal('system error:0516-306 getlvodm: Unable to find volume group foovg in the Device', exception.message[0,79])
  end

  def test_06_increase
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'part1')
    @stobj.increase(10)
    assert_equal(30, @stobj.get_nbpp)

    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'part3')
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.increase(20)
    }
    assert_equal('system error:0516-306 getlvodm: Unable to find  part3 in the Device', exception.message[0,67])
  end

  def test_08_copies
    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'part1')
    @stobj.change_copies(2)

    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'part1')
    @stobj.change_copies(-1)

    @stobj = AIXLVM::StObjLV.new(AIXLVM::System.new(),'part3')
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.change_copies(2)
    }
    assert_equal('system error:0516-312 mklvcopy: Unable to find logical volume part3 in the Device', exception.message[0,81])
  end

end

class TestAIXStorage_FS < Test::Unit::TestCase
  def setup
    print("\n")
    system("umount /opt/data1 2>/dev/null")
    system("umount /opt/data2 2>/dev/null")
    system("varyoffvg datavg 2>/dev/null")
    system("exportvg datavg 2>/dev/null")
    system("mkvg -y datavg -s 4 -f hdisk1 2>/dev/null")
    system("mklv -t jfs2 -y part1 datavg 256 2>/dev/null")
    system("mklv -t jfs2 -y part2 datavg 256 2>/dev/null")
    system("crfs -v jfs2 -d part1 -m /opt/data1 -A yes 2>/dev/null")
    system("chfs -a size=64M /opt/data1 2>/dev/null")
  end

  def teardown
    system("umount /opt/data1 2>/dev/null")
    system("umount /opt/data2 2>/dev/null")
    system("varyoffvg datavg 2>/dev/null")
    system("exportvg datavg 2>/dev/null")
  end

  def test_01_exists
    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data1')
    assert_equal(true, @stobj.exist?)
    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data2')
    assert_equal(false, @stobj.exist?)
  end

  def test_02_get_size
    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data1')
    assert_equal(64, @stobj.get_size)
    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data2')
    assert_equal(nil, @stobj.get_size)
  end

  def test_03_create
    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data2')
    @stobj.create('part2')
    assert_equal(true, @stobj.exist?)

    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data3')
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.create('part1')
    }
    assert_equal('system error:crfs: lv /dev/part1 already being used for filesystem /opt/data1', exception.message[0,77])
  end

  def test_04_modify
    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data1')
    @stobj.modify(128)
    assert_equal(128, @stobj.get_size)

    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data1')
    @stobj.modify(32)
    assert_equal(32, @stobj.get_size)

    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data1')
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.modify(8192)
    }
    assert_equal('system error:0516-787 extendlv: Maximum allocation for logical volume part1', exception.message[0,75])
  end

  def test_05_mount_umount
    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data1')
    assert_equal(false, @stobj.mounted?)
    @stobj.mount
    assert_equal(true, @stobj.mounted?)
    @stobj.umount
    assert_equal(false, @stobj.mounted?)
  end

  def test_06_format
    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data1')
    assert_equal('jfs2', @stobj.get_format)
    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data3')
    assert_equal(nil, @stobj.get_format)
  end

  def test_07_readonly
    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data1')
    assert_equal(false, @stobj.readonly?)
    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data3')
    assert_equal(nil, @stobj.readonly?)
  end

  def test_08_defrag
    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data1')
    @stobj.mount
    @stobj.defragfs()

    @stobj = AIXLVM::StObjFS.new(AIXLVM::System.new(),'/opt/data3')
    exception = assert_raise(AIXLVM::LVMException) {
      @stobj.defragfs()
    }
    assert_equal('system error:/sbin/helpers/cdrfs/fstype: No such file or directory', exception.message[0,66])
  end

end