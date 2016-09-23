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
require_relative '../../../libraries/lvmobj_vg'
require_relative 'mock'

class TestVolumGroup < Test::Unit::TestCase
  def setup
    print("\n")
    @mock = MockSystem.new
    @volgroup = AIXLVM::VolumeGroup.new('datavg', @mock)
    @volgroup.physical_volumes = %w(hdisk1 hdisk2)
    @volgroup.use_as_hot_spare = 'n'
    @volgroup.mirror_pool_name = nil
  end

  ############################### BASIC TESTS ###############################

  def test_01_pv_dont_exists
    # One or more of the specified physical volume names do not exist
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lspv | grep "hdisk2 "', nil)

    exception = assert_raise(AIXLVM::LVMException) do
      @volgroup.check_to_change
    end
    assert_equal('physical volume "hdisk2" does not exist!', exception.message)
    assert_equal('', @mock.residual)
  end

  def test_02_pv_are_already_use
    # One or more of the specified physical volumes are use in a different volume group
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk2                   VOLUME GROUP:     foovg')

    exception = assert_raise(AIXLVM::LVMException) do
      @volgroup.check_to_change
    end
    assert_equal('physical volume "hdisk2" is use in a different volume group!', exception.message)
    assert_equal('', @mock.residual)
  end

  def test_03_vg_not_exist
    # VG not exist and not error case
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lsvg datavg', nil)
    @mock.add_retrun('mkvg -y datavg -S -f hdisk1', '')
    @mock.add_retrun('extendvg -f datavg hdisk2', '')
    assert_equal(true, @volgroup.check_to_change)
    assert_equal(["Create volume groupe 'datavg'", "Extending 'hdisk1' to 'datavg'", "Extending 'hdisk2' to 'datavg'"], @volgroup.create)
    assert_equal('', @mock.residual)
  end

  def test_04_vg_exist_no_change
    # VG exist and not error case
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk2                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes)
    LVs:                2                        USED PPs:       768 (3072 megabytes)
    OPEN LVs:           0                        QUORUM:         2 (Enabled)
    TOTAL PVs:          3                        VG DESCRIPTORS: 3
    STALE PVs:          0                        STALE PPs:      0
    ACTIVE PVs:         3                        AUTO ON:        yes
    MAX PPs per VG:     32768                    MAX PVs:        1024
    LTG size (Dynamic): 512 kilobyte(s)          AUTO SYNC:      no
    HOT SPARE:          no                       BB POLICY:      relocatable
    MIRROR POOL STRICT: off
    PV RESTRICTION:     none                     INFINITE RETRY: no
    DISK BLOCK SIZE:    512                      CRITICAL VG:    no
')
    @mock.add_retrun('lsvg -p datavg', 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205
    hdisk2            active            1023        1023        205..205..204..204..205')
    @mock.add_retrun("lspv -P | grep 'datavg'", '')
    assert_equal(false, @volgroup.check_to_change)
    assert_equal([], @volgroup.create)
    assert_equal('', @mock.residual)
  end

  def test_05_vg_exist_with_change_add_disk
    # VG exist and not error case
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes)
    LVs:                2                        USED PPs:       768 (3072 megabytes)
    OPEN LVs:           0                        QUORUM:         2 (Enabled)
    TOTAL PVs:          3                        VG DESCRIPTORS: 3
    STALE PVs:          0                        STALE PPs:      0
    ACTIVE PVs:         3                        AUTO ON:        yes
    MAX PPs per VG:     32768                    MAX PVs:        1024
    LTG size (Dynamic): 512 kilobyte(s)          AUTO SYNC:      no
    HOT SPARE:          no                       BB POLICY:      relocatable
    MIRROR POOL STRICT: off
    PV RESTRICTION:     none                     INFINITE RETRY: no
    DISK BLOCK SIZE:    512                      CRITICAL VG:    no
')
    @mock.add_retrun('lsvg -p datavg', 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205')
    @mock.add_retrun("lspv -P | grep 'datavg'", '')
    @mock.add_retrun('extendvg -f datavg hdisk2', '')
    assert_equal(true, @volgroup.check_to_change)
    assert_equal(["Extending 'hdisk2' to 'datavg'"], @volgroup.create)
    assert_equal('', @mock.residual)
  end

  def test_06_vg_exist_with_change_remove_disk
    # VG exist and not error case
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes)
    LVs:                2                        USED PPs:       768 (3072 megabytes)
    OPEN LVs:           0                        QUORUM:         2 (Enabled)
    TOTAL PVs:          3                        VG DESCRIPTORS: 3
    STALE PVs:          0                        STALE PPs:      0
    ACTIVE PVs:         3                        AUTO ON:        yes
    MAX PPs per VG:     32768                    MAX PVs:        1024
    LTG size (Dynamic): 512 kilobyte(s)          AUTO SYNC:      no
    HOT SPARE:          no                       BB POLICY:      relocatable
    MIRROR POOL STRICT: off
    PV RESTRICTION:     none                     INFINITE RETRY: no
    DISK BLOCK SIZE:    512                      CRITICAL VG:    no
')
    @mock.add_retrun('lsvg -p datavg', 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205
    hdisk2            active            1023        1023        205..205..204..204..205
    hdisk3            active            1023        1023        205..205..204..204..205')
    @mock.add_retrun("lspv -P | grep 'datavg'", '')
    @mock.add_retrun('reducevg -d datavg hdisk3', '')
    assert_equal(true, @volgroup.check_to_change)
    assert_equal(["Reducing 'hdisk3' to 'datavg'"], @volgroup.create)
    assert_equal('', @mock.residual)
  end

  def test_07_vg_exist_with_change__add_remove_disk
    # VG exist and not error case
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes)
    LVs:                2                        USED PPs:       768 (3072 megabytes)
    OPEN LVs:           0                        QUORUM:         2 (Enabled)
    TOTAL PVs:          3                        VG DESCRIPTORS: 3
    STALE PVs:          0                        STALE PPs:      0
    ACTIVE PVs:         3                        AUTO ON:        yes
    MAX PPs per VG:     32768                    MAX PVs:        1024
    LTG size (Dynamic): 512 kilobyte(s)          AUTO SYNC:      no
    HOT SPARE:          no                       BB POLICY:      relocatable
    MIRROR POOL STRICT: off
    PV RESTRICTION:     none                     INFINITE RETRY: no
    DISK BLOCK SIZE:    512                      CRITICAL VG:    no
')
    @mock.add_retrun('lsvg -p datavg', 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205
    hdisk3            active            1023        1023        205..205..204..204..205')
    @mock.add_retrun("lspv -P | grep 'datavg'", '')
    @mock.add_retrun('extendvg -f datavg hdisk2', '')
    @mock.add_retrun('reducevg -d datavg hdisk3', '')
    assert_equal(true, @volgroup.check_to_change)
    assert_equal(["Extending 'hdisk2' to 'datavg'", "Reducing 'hdisk3' to 'datavg'"], @volgroup.create)
    assert_equal('', @mock.residual)
  end

  ############################### ADVANCED TESTS ###############################

  def test_10_pv_are_manage_by_thirdvm
    # One or more of the specified physical volumes are managed by third-party volume manager
    print("??? third-party volume manager ???\n")
    nil
  end

  def test_11_bad_block_sizes
    # The block sizes of all the specified physical volumes are not identical
    print("??? block sizes of a PV ???\n")
    nil
  end

  def test_12_illegal_mirror_pool_name
    @volgroup.mirror_pool_name = 'sz!erf-22'
    exception = assert_raise(AIXLVM::LVMException) do
      @volgroup.check_to_change
    end
    assert_equal('illegal_mirror_pool_name!', exception.message)
    @volgroup.mirror_pool_name = 'copy0poolcopy0pool'
    exception = assert_raise(AIXLVM::LVMException) do
      @volgroup.check_to_change
    end
    assert_equal('illegal_mirror_pool_name!', exception.message)
    assert_equal('', @mock.residual)
  end

  def test_13_vg_not_exist_with_hot_spare
    # VG not exist and not error case
    @volgroup.use_as_hot_spare = 'y'
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lsvg datavg', nil)
    @mock.add_retrun('mkvg -y datavg -S -f hdisk1', '')
    @mock.add_retrun('chvg -h y datavg', '')
    @mock.add_retrun('extendvg -f datavg hdisk2', '')
    assert_equal(true, @volgroup.check_to_change)
    assert_equal(["Create volume groupe 'datavg'", "Extending 'hdisk1' to 'datavg'", "Extending 'hdisk2' to 'datavg'"], @volgroup.create)
    assert_equal('', @mock.residual)
  end

  def test_14_vg_not_exist_with_mirror_pool
    # VG not exist and not error case
    @volgroup.mirror_pool_name = 'copy0pool'
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", nil)
    @mock.add_retrun('lsvg datavg', nil)
    @mock.add_retrun('mkvg -y datavg -S -p copy0pool -f hdisk1', '')
    @mock.add_retrun('extendvg -p copy0pool -f datavg hdisk2', '')
    assert_equal(true, @volgroup.check_to_change)
    assert_equal(["Create volume groupe 'datavg'", "Extending 'hdisk1' to 'datavg'", "Extending 'hdisk2' to 'datavg'"], @volgroup.create)
    assert_equal('', @mock.residual)
  end

  def test_15_vg_exist_change_hot_spare
    # VG exist and not error case
    @volgroup.use_as_hot_spare = 'y'
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk2                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes)
    LVs:                2                        USED PPs:       768 (3072 megabytes)
    OPEN LVs:           0                        QUORUM:         2 (Enabled)
    TOTAL PVs:          3                        VG DESCRIPTORS: 3
    STALE PVs:          0                        STALE PPs:      0
    ACTIVE PVs:         3                        AUTO ON:        yes
    MAX PPs per VG:     32768                    MAX PVs:        1024
    LTG size (Dynamic): 512 kilobyte(s)          AUTO SYNC:      no
    HOT SPARE:          no                       BB POLICY:      relocatable
    MIRROR POOL STRICT: off
    PV RESTRICTION:     none                     INFINITE RETRY: no
    DISK BLOCK SIZE:    512                      CRITICAL VG:    no
')
    @mock.add_retrun('lsvg -p datavg', 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205
    hdisk2            active            1023        1023        205..205..204..204..205')
    @mock.add_retrun("lspv -P | grep 'datavg'", '')
    @mock.add_retrun('chvg -h y datavg', '')
    assert_equal(true, @volgroup.check_to_change)
    assert_equal(["Modify 'datavg'"], @volgroup.create)
    assert_equal('', @mock.residual)
  end

  def test_16_vg_exist_change_mirror_pool
    # VG exist and not error case
    @volgroup.mirror_pool_name = 'copy0pool'
    @mock.add_retrun('lspv | grep "hdisk1 "', 'hdisk1  00f9fd4bf0d1ce48  None')
    @mock.add_retrun("lspv hdisk1 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk1                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lspv | grep "hdisk2 "', 'hdisk2  00f9fd4bf0d4e037  None')
    @mock.add_retrun("lspv hdisk2 | grep 'VOLUME GROUP:'", 'PHYSICAL VOLUME:    hdisk2                   VOLUME GROUP:     datavg')
    @mock.add_retrun('lsvg datavg', 'VOLUME GROUP:       datavg                   VG IDENTIFIER:  00f9fd4b00004c00000001547adb7ade
    VG STATE:           active                   PP SIZE:        4 megabyte(s)
    VG PERMISSION:      read/write               TOTAL PPs:      3018 (12072 megabytes)
    MAX LVs:            256                      FREE PPs:       2250 (9000 megabytes)
    LVs:                2                        USED PPs:       768 (3072 megabytes)
    OPEN LVs:           0                        QUORUM:         2 (Enabled)
    TOTAL PVs:          3                        VG DESCRIPTORS: 3
    STALE PVs:          0                        STALE PPs:      0
    ACTIVE PVs:         3                        AUTO ON:        yes
    MAX PPs per VG:     32768                    MAX PVs:        1024
    LTG size (Dynamic): 512 kilobyte(s)          AUTO SYNC:      no
    HOT SPARE:          no                       BB POLICY:      relocatable
    MIRROR POOL STRICT: off
    PV RESTRICTION:     none                     INFINITE RETRY: no
    DISK BLOCK SIZE:    512                      CRITICAL VG:    no
')
    @mock.add_retrun('lsvg -p datavg', 'datavg:
    PV_NAME           PV STATE          TOTAL PPs   FREE PPs    FREE DISTRIBUTION
    hdisk1            active            1023        1023        205..205..204..204..205
    hdisk2            active            1023        1023        205..205..204..204..205')
    @mock.add_retrun("lspv -P | grep 'datavg'", '')
    assert_equal(false, @volgroup.check_to_change)
    assert_equal([], @volgroup.create)
    assert_equal('', @mock.residual)
  end
end
