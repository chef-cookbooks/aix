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
  class VolumeGroup
    attr_accessor :physical_volumes
    attr_accessor :use_as_hot_spare
    attr_accessor :mirror_pool_name
    def initialize(name, system)
      @name = name
      @system = system
      @physical_volumes = []
      @use_as_hot_spare = 'n'
      @mirror_pool_name = nil

      @current_physical_volumes = []
      @changed = false
    end

    def check_to_change
      @changed = true
      if !@mirror_pool_name.nil? && !(@mirror_pool_name =~ /^[0-9a-zA-Z]{1,15}$/)
        raise AIXLVM::LVMException.new('illegal_mirror_pool_name!')
      end
      for current_pv in @physical_volumes
        pv_obj = StObjPV.new(@system, current_pv)
        unless pv_obj.exist?
          raise AIXLVM::LVMException.new('physical volume "%s" does not exist!' % current_pv)
        end
        current_vg = pv_obj.get_vgname
        if !current_vg.nil? && current_vg != @name
          raise AIXLVM::LVMException.new('physical volume "%s" is use in a different volume group!' % current_pv)
        end
      end
      @current_physical_volumes = []
      vg_obj = StObjVG.new(@system, @name)
      if vg_obj.exist?
        @current_physical_volumes = vg_obj.get_pv_list
        current_hot_spare = vg_obj.hot_spare?
        @use_as_hot_spare = nil if current_hot_spare == (@use_as_hot_spare == 'y')
        vg_obj.get_mirrorpool
        @changed = (@physical_volumes.sort != @current_physical_volumes.sort) || !@use_as_hot_spare.nil?
      end
      @changed
    end

    def create
      ret = []
      if @changed
        vg_obj = StObjVG.new(@system, @name)
        if @current_physical_volumes.empty?
          vg_obj.create(@physical_volumes[0], @mirror_pool_name)
          ret.push("Create volume groupe '%s'" % @name)
          vg_obj.modify('y') if @use_as_hot_spare == 'y'
          ret.push("Extending '%s' to '%s'" % [@physical_volumes[0], @name])
          @current_physical_volumes.push(@physical_volumes[0])
        else
          unless @use_as_hot_spare.nil?
            vg_obj.modify(@use_as_hot_spare)
            ret.push("Modify '%s'" % [@name])
          end
        end
        for sub_pv in @physical_volumes.sort
          unless @current_physical_volumes.include?(sub_pv)
            ret.push("Extending '%s' to '%s'" % [sub_pv, @name])
            vg_obj.add_pv(sub_pv, @mirror_pool_name)
          end
        end
        for old_pv in @current_physical_volumes.sort
          unless @physical_volumes.include?(old_pv)
            ret.push("Reducing '%s' to '%s'" % [old_pv, @name])
            vg_obj.delete_pv(old_pv)
          end
        end
      end
      ret
    end
  end
end
