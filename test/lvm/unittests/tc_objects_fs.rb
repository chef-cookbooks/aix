#
# Copyright 2016, International Business Machines Corporation
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

require 'test/unit'

require_relative '../../../libraries/tools'
require_relative '../../../libraries/lvmobj_fs'
require_relative 'mock'

class TestFileSystem < Test::Unit::TestCase
  def setup
    print("\n")
    @mock = MockSystem.new
    @filesystem = AIXLVM::FileSystem.new('/opt/data', @mock)
    @filesystem.logical_volume = 'lv22'
    @filesystem.size = '250M'
  end

  ############################### BASIC TESTS ###############################

  def test_01_lv_dont_exists
    @mock.add_retrun('lslv lv22', nil)

    exception = assert_raise(AIXLVM::LVMException) do
      @filesystem.check_to_change
    end
    assert_equal('logical volume "lv22" does not exist!', exception.message)
    assert_equal('', @mock.residual)
  end

  def test_02_fs_are_already_use_in_different_lv
    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        32 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            1
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        /                      LABEL:          /
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    exception = assert_raise(AIXLVM::LVMException) do
      @filesystem.check_to_change
    end
    assert_equal('logical volume "lv22" has already another file system!', exception.message)
    assert_equal('', @mock.residual)
  end

  def test_03_size_invalid
    @filesystem.size = '250k'
    exception = assert_raise(AIXLVM::LVMException) do
      @filesystem.check_to_change
    end
    assert_equal('Invalid size!', exception.message)

    @filesystem.size = 'abc'
    exception = assert_raise(AIXLVM::LVMException) do
      @filesystem.check_to_change
    end
    assert_equal('Invalid size!', exception.message)

    @filesystem.size = '25.14.14'
    exception = assert_raise(AIXLVM::LVMException) do
      @filesystem.check_to_change
    end
    assert_equal('Invalid size!', exception.message)
    assert_equal('', @mock.residual)

    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        32 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            1024
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        N/A                    LABEL:          None
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun('lsfs -c /opt/data', nil)
    @filesystem.size = '25G'
    assert_equal(true, @filesystem.check_to_change)
  end

  def test_04_insufficient_space_available_not_exist
    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        4 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            60
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        N/A                    LABEL:          None
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun('lsfs -c /opt/data', nil)
    exception = assert_raise(AIXLVM::LVMException) do
      @filesystem.check_to_change
    end
    assert_equal('Insufficient space available!', exception.message)
    assert_equal('', @mock.residual)
  end

  def test_05_insufficient_space_available_exist
    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        4 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            60
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        /opt/data              LABEL:          /opt/data
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun('lsfs -c /opt/data', "#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:part1:jfs2:::2031616:rw:yes:no")
    exception = assert_raise(AIXLVM::LVMException) do
      @filesystem.check_to_change
    end
    assert_equal('Insufficient space available!', exception.message)
    assert_equal('', @mock.residual)
  end

  def test_06_fs_not_exist
    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        4 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            100
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        N/A                    LABEL:          None
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun('lsfs -c /opt/data', nil)
    @mock.add_retrun('crfs -v jfs2 -d lv22 -m /opt/data -A yes', '')
    @mock.add_retrun('chfs -a size=250M /opt/data', '')
    assert_equal(true, @filesystem.check_to_change)
    assert_equal(["Create file system '/opt/data' on logical volume 'lv22'"], @filesystem.create)
    assert_equal('', @mock.residual)
  end

  def test_07_fs_exist_no_change
    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        4 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            100
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        /opt/data              LABEL:          /opt/data
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun('lsfs -c /opt/data', "#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:lv22:jfs2:::512000:rw:yes:no")
    assert_equal(false, @filesystem.check_to_change)
    assert_equal([], @filesystem.create)
    assert_equal('', @mock.residual)
  end

  def test_08_fs_exist_with_size_increase
    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        4 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            100
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        /opt/data              LABEL:          /opt/data
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun('lsfs -c /opt/data', "#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:lv22:jfs2:::250:rw:yes:no")
    @mock.add_retrun('chfs -a size=250M /opt/data', '')
    assert_equal(true, @filesystem.check_to_change)
    assert_equal(["Modify file system '/opt/data'"], @filesystem.create)
    assert_equal('', @mock.residual)
  end

  def test_09_fs_exist_with_size_reduce
    @mock.add_retrun('lslv lv22', 'LOGICAL VOLUME:     lv22                    VOLUME GROUP:   rootvg
LV IDENTIFIER:      00f9fd4b00004c0000000153e61e5d00.8 PERMISSION:     read/write
VG STATE:           active/complete        LV STATE:       opened/syncd
TYPE:               jfs2                   WRITE VERIFY:   off
MAX LPs:            512                    PP SIZE:        4 megabyte(s)
COPIES:             1                      SCHED POLICY:   parallel
LPs:                1                      PPs:            100
STALE PPs:          0                      BB POLICY:      relocatable
INTER-POLICY:       minimum                RELOCATABLE:    yes
INTRA-POLICY:       center                 UPPER BOUND:    32
MOUNT POINT:        /opt/data              LABEL:          /opt/data
MIRROR WRITE CONSISTENCY: on/ACTIVE
EACH LP COPY ON A SEPARATE PV ?: yes
Serialize IO ?:     NO
INFINITE RETRY:     no
')
    @mock.add_retrun('lsfs -c /opt/data', "#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:lv22:jfs2:::1000:rw:yes:no")
    @mock.add_retrun('chfs -a size=250M /opt/data', '')
    assert_equal(true, @filesystem.check_to_change)
    assert_equal(["Modify file system '/opt/data'"], @filesystem.create)
    assert_equal('', @mock.residual)
  end

  def test_10_fs_not_exist_mount_umount
    @mock.add_retrun('lsfs -c /opt/data', nil)
    @filesystem.logical_volume = ''
    @filesystem.size = ''
    exception = assert_raise(AIXLVM::LVMException) do
      @filesystem.check_to_mount(true)
    end
    assert_equal("Filesystem doesn't exist!", exception.message)
    assert_equal('', @mock.residual)
  end

  def test_11_fs_exist_mount_fail
    @mock.add_retrun('lsfs -c /opt/data', "#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:lv22:jfs2:::1000:rw:yes:no")
    @mock.add_retrun('mount | grep /opt/data', '         /dev/part2       /opt/data     jfs2   May 27 12:04 rw,log=/dev/loglv00')
    @filesystem.logical_volume = ''
    @filesystem.size = ''
    assert_equal(false, @filesystem.check_to_mount(true))
    assert_equal('', @mock.residual)
  end

  def test_12_fs_exist_umount_fail
    @mock.add_retrun('lsfs -c /opt/data', "#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:lv22:jfs2:::1000:rw:yes:no")
    @mock.add_retrun('mount | grep /opt/data', nil)
    @filesystem.logical_volume = ''
    @filesystem.size = ''
    assert_equal(false, @filesystem.check_to_mount(false))
    assert_equal('', @mock.residual)
  end

  def test_13_fs_exist_mount_success
    @mock.add_retrun('lsfs -c /opt/data', "#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:lv22:jfs2:::1000:rw:yes:no")
    @mock.add_retrun('mount | grep /opt/data', nil)
    @mock.add_retrun('mount /opt/data', '')
    @filesystem.logical_volume = ''
    @filesystem.size = ''
    assert_equal(true, @filesystem.check_to_mount(true))
    assert_equal(["File system '/opt/data' mounted"], @filesystem.mount)
    assert_equal('', @mock.residual)
  end

  def test_14_fs_exist_umount_success
    @mock.add_retrun('lsfs -c /opt/data', "#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:lv22:jfs2:::1000:rw:yes:no")
    @mock.add_retrun('mount | grep /opt/data', '         /dev/part2       /opt/data     jfs2   May 27 12:04 rw,log=/dev/loglv00')
    @mock.add_retrun('umount /opt/data', '')
    @filesystem.logical_volume = ''
    @filesystem.size = ''
    assert_equal(true, @filesystem.check_to_mount(false))
    assert_equal(["File system '/opt/data' umounted"], @filesystem.umount)
    assert_equal('', @mock.residual)
  end

  def test_15_fs_notexist_defrag_fail
    @mock.add_retrun('lsfs -c /opt/data', nil)
    @filesystem.logical_volume = ''
    @filesystem.size = ''
    exception = assert_raise(AIXLVM::LVMException) do
      @filesystem.check_to_defrag
    end
    assert_equal("Filesystem doesn't exist!", exception.message)
    assert_equal('', @mock.residual)
  end

  def test_16_fs_badformat_defrag_fail
    @mock.add_retrun('lsfs -c /opt/data', "#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:lv22:jfs:::1000:rw:yes:no")
    @filesystem.logical_volume = ''
    @filesystem.size = ''
    exception = assert_raise(AIXLVM::LVMException) do
      @filesystem.check_to_defrag
    end
    assert_equal("Filesystem doesn't jfs2!", exception.message)
    assert_equal('', @mock.residual)
  end

  def test_17_fs_readonly_defrag_fail
    @mock.add_retrun('lsfs -c /opt/data', "#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
  /opt/data:lv22:jfs2:::1000:r:yes:no")
    @filesystem.logical_volume = ''
    @filesystem.size = ''
    exception = assert_raise(AIXLVM::LVMException) do
      @filesystem.check_to_defrag
    end
    assert_equal('Filesystem is readonly!', exception.message)
    assert_equal('', @mock.residual)
  end

  def test_18_fs_notmount_defrag_fail
    @mock.add_retrun('lsfs -c /opt/data', "#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:lv22:jfs2:::1000:rw:yes:no")
    @mock.add_retrun('mount | grep /opt/data', nil)
    @filesystem.logical_volume = ''
    @filesystem.size = ''
    exception = assert_raise(AIXLVM::LVMException) do
      @filesystem.check_to_defrag
    end
    assert_equal("Filesystem doesn't mount!", exception.message)
    assert_equal('', @mock.residual)
  end

  def test_19_fs_defrag
    @mock.add_retrun('lsfs -c /opt/data', "#MountPoint:Device:Vfs:Nodename:Type:Size:Options:AutoMount:Acct
/opt/data:lv22:jfs2:::1000:rw:yes:no")
    @mock.add_retrun('mount | grep /opt/data', '         /dev/part2       /opt/data     jfs2   May 27 12:04 rw,log=/dev/loglv00')
    @mock.add_retrun('defragfs /opt/data', '')
    @filesystem.logical_volume = ''
    @filesystem.size = ''
    assert_equal(true, @filesystem.check_to_defrag)
    assert_equal(["File system '/opt/data' defraged"], @filesystem.defragfs)
  end
end
