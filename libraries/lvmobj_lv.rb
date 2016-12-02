#
# Copyright:: 2016, International Business Machines Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative 'storage_objects'

module AIXLVM
  class LogicalVolume
    attr_accessor :group
    attr_accessor :physical_volumes
    attr_accessor :size
    attr_accessor :copies # [1, 2, 3]
    def initialize(name, system)
      @name = name
      @system = system
      @group = ''
      @physical_volumes = []
      @size = 0
      @copies = 1

      @nb_pp = 0
      @diff_pp = 0
      @current_copies = 1
      @changed = false
    end

    def check_to_change
      @changed = true
      unless [1, 2, 3].include?(@copies)
        raise AIXLVM::LVMException.new('Illegal number of copies!')
      end
      vg_obj = StObjVG.new(@system, @group)
      unless vg_obj.exist?
        raise AIXLVM::LVMException.new('volume group "%s" does not exist!' % @group)
      end
      if vg_obj.get_nbpv < @copies
        raise AIXLVM::LVMException.new('Illegal number of copies!')
      end
      ppsize = vg_obj.get_ppsize
      @nb_pp = @size.to_f / ppsize.to_f
      if @nb_pp != @nb_pp.to_i
        raise AIXLVM::LVMException.new('size must be multiple to the PP size!')
      end
      lv_obj = StObjLV.new(@system, @name)
      current_volgroup = lv_obj.get_vg
      if !current_volgroup.nil?
        if current_volgroup != @group
          raise AIXLVM::LVMException.new('logical volume "%s" exist with other volume group!' % @name)
        end
        current_size = lv_obj.get_nbpp
        @diff_pp = @nb_pp - current_size
        if @diff_pp > 0
          free_pp_in_vg = vg_obj.get_freepp
          if free_pp_in_vg < @diff_pp
            raise AIXLVM::LVMException.new('Insufficient space available!')
          end
        else
          @current_copies = lv_obj.get_copies
          @copies = -@copies if @copies < @current_copies
          @changed = (@diff_pp != 0) || (@copies != @current_copies)
        end
      else
        @diff_pp = -1
        free_pp_in_vg = vg_obj.get_freepp
        if free_pp_in_vg < @nb_pp
          raise AIXLVM::LVMException.new('Insufficient space available!')
        end
      end
      @changed
    end

    def create
      ret = []
      if @changed
        lv_obj = StObjLV.new(@system, @name)
        if @diff_pp == -1
          lv_obj.create(@group, @nb_pp, @copies)
          ret.push("Create logical volume '%s' on volume groupe '%s'" % [@name, @group])
        else
          lv_obj.increase(@diff_pp) if @diff_pp > 0
          lv_obj.change_copies(@copies) if @copies != @current_copies
          ret.push("Modify logical volume '%s'" % @name)
        end
      end
      ret
    end
  end
end
