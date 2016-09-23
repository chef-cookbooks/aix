#
# Copyright 2016, International Business Machines Corporation
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

module AIXLVM
  class StObjPV
    def initialize(system, name)
      @system = system
      @name = name
    end

    def exist?
      out = @system.run('lspv | grep "%s "' % @name)
      !out.nil?
    end

    def get_vgname
      out = @system.run("lspv %s | grep 'VOLUME GROUP:'" % @name)
      if !out.nil?
        return out[/VOLUME GROUP:\s*(.*)/, 1]
      else
        return nil
      end
    end

    def get_size
      out = @system.run('bootinfo -s %s' % @name)
      if !out.nil?
        return out.to_i
      else
        return 0
      end
    end
  end

  class StObjVG
    def initialize(system, name)
      @system = system
      @name = name
      @descript = 0
    end

    def read
      @descript = @system.run('lsvg %s' % @name) if @descript == 0
    end

    def exist?
      read
      !@descript.nil?
    end

    def get_pv_list
      pv_list = []
      out = @system.run('lsvg -p %s' % @name)
      unless out.nil?
        header = true
        out.split("\n").each do |line|
          if header
            header = (line[/PV_NAME/] != 'PV_NAME')
          else
            pv_list.push(line[/([^\s]+)/, 1])
          end
        end
      end
      pv_list
    end

    def hot_spare?
      read
      if !@descript.nil?
        return @descript[/HOT SPARE:\s*([^\s]*)\s.*/, 1] != 'no'
      else
        return nil
      end
    end

    def get_ppsize
      read
      if !@descript.nil?
        return @descript[/PP SIZE:\s*(.*)\s*/, 1].to_i
      else
        return nil
      end
    end

    def get_freepp
      read
      if !@descript.nil?
        return @descript[/FREE PPs:\s*(.*)\s*/, 1].to_i
      else
        return nil
      end
    end

    def get_totalpp
      read
      if !@descript.nil?
        return @descript[/TOTAL PPs:\s*(.*)\s*/, 1].to_i
      else
        return nil
      end
    end

    def get_mirrorpool
      out = @system.run("lspv -P | grep '%s'" % @name)
      if !out.nil?
        mirror_pool = nil
        reg_exp = /^.*#{@name}\s+([^\s]*)$/
        for line in out.split("\n")
          current_pool = line[reg_exp, 1]
          current_pool = '' if current_pool.nil?
          if mirror_pool.nil?
            mirror_pool = current_pool
          else
            mirror_pool = '???' if mirror_pool != current_pool
          end
        end
        return mirror_pool
      else
        return nil
      end
    end

    def get_nbpv
      read
      if !@descript.nil?
        return @descript[/ACTIVE PVs:\s*(.*)\s*/, 1].to_i
      else
        return nil
      end
    end

    def create(pvname, mirrorpool)
      cmd = if mirrorpool.nil?
              'mkvg -y %s -S -f %s' % [@name, pvname]
            else
              'mkvg -y %s -S -p %s -f %s' % [@name, mirrorpool, pvname]
            end
      out = @system.run(cmd)
      if !out.nil?
        return out
      else
        raise AIXLVM::LVMException.new('system error:%s' % @system.last_error)
      end
    end

    def modify(hot_spot)
      out = @system.run('chvg -h %s %s' % [hot_spot, @name])
      if !out.nil?
        return out
      else
        raise AIXLVM::LVMException.new('system error:%s' % @system.last_error)
      end
    end

    def add_pv(pvname, mirrorpool)
      cmd = if mirrorpool.nil?
              'extendvg -f %s %s' % [@name, pvname]
            else
              'extendvg -p %s -f %s %s' % [mirrorpool, @name, pvname]
            end
      out = @system.run(cmd)
      if !out.nil?
        return out
      else
        raise AIXLVM::LVMException.new('system error:%s' % @system.last_error)
      end
    end

    def delete_pv(pvname)
      out = @system.run('reducevg -d %s %s' % [@name, pvname])
      if !out.nil?
        return out
      else
        raise AIXLVM::LVMException.new('system error:%s' % @system.last_error)
      end
    end
  end

  class StObjLV
    def initialize(system, name)
      @system = system
      @name = name
      @descript = 0
    end

    def read
      @descript = @system.run('lslv %s' % @name) if @descript == 0
    end

    def exist?
      read
      !@descript.nil?
    end

    def get_vg
      read
      if !@descript.nil?
        return @descript[/VOLUME GROUP:\s*(.*)\s*/, 1]
      else
        return nil
      end
    end

    def get_ppsize
      read
      if !@descript.nil?
        return @descript[/PP SIZE:\s*(.*)\s*/, 1].to_i
      else
        return nil
      end
    end

    def get_nbpp
      read
      if !@descript.nil?
        return @descript[/PPs:\s*(.*)\s*/, 1].to_i
      else
        return nil
      end
    end

    def get_mount
      read
      if !@descript.nil?
        val = @descript[/MOUNT POINT:\s*([^\s]*)\s/, 1]
        if val == 'N/A'
          return ''
        else
          return val
        end
      else
        return nil
      end
    end

    def get_copies
      read
      if !@descript.nil?
        return @descript[/COPIES:\s*(.*)\s*/, 1].to_i
      else
        return nil
      end
    end

    def create(vgname, nb_pp, copies)
      out = @system.run('mklv -c %d -t jfs2 -y %s %s %d' % [copies, @name, vgname, nb_pp])
      if !out.nil?
        return out
      else
        raise AIXLVM::LVMException.new('system error:%s' % @system.last_error)
      end
    end

    def increase(diff_pp)
      out = @system.run('extendlv %s %d' % [@name, diff_pp])
      if !out.nil?
        return out
      else
        raise AIXLVM::LVMException.new('system error:%s' % @system.last_error)
      end
    end

    def change_copies(copies)
      out = if copies > 0
              @system.run('mklvcopy %s %d' % [@name, copies])
            else
              @system.run('rmlvcopy %s %d' % [@name, -1 * copies])
            end
      if !out.nil?
        return out
      else
        raise AIXLVM::LVMException.new('system error:%s' % @system.last_error)
      end
    end
  end

  class StObjFS
    def initialize(system, name)
      @system = system
      @name = name
      @descript = 0
    end

    def read
      @descript = @system.run('lsfs -c %s' % @name) if @descript == 0
    end

    def exist?
      read
      !@descript.nil?
    end

    def get_size
      read
      if !@descript.nil?
        lines = @descript.split("\n")
        vals = lines[1].split(':')
        return vals[5].to_f / 2048
      else
        return nil
      end
    end

    def get_format
      read
      if !@descript.nil?
        lines = @descript.split("\n")
        vals = lines[1].split(':')
        return vals[2]
      else
        return nil
      end
    end

    def readonly?
      read
      if !@descript.nil?
        lines = @descript.split("\n")
        vals = lines[1].split(':')
        return !vals[6].include?('rw')
      else
        return nil
      end
    end

    def create(lvname)
      out = @system.run('crfs -v jfs2 -d %s -m %s -A yes' % [lvname, @name])
      if !out.nil?
        return out
      else
        raise AIXLVM::LVMException.new('system error:%s' % @system.last_error)
      end
    end

    def modify(size)
      out = @system.run('chfs -a size=%dM %s' % [size, @name])
      if !out.nil?
        return out
      else
        raise AIXLVM::LVMException.new('system error:%s' % @system.last_error)
      end
    end

    def mounted?
      out = @system.run('mount | grep %s' % [@name])
      !out.nil?
    end

    def mount
      out = @system.run('mount %s' % [@name])
      if !out.nil?
        return out
      else
        raise AIXLVM::LVMException.new('system error:%s' % @system.last_error)
      end
    end

    def umount
      out = @system.run('umount %s' % [@name])
      if !out.nil?
        return out
      else
        raise AIXLVM::LVMException.new('system error:%s' % @system.last_error)
      end
    end

    def defragfs
      out = @system.run('defragfs %s' % [@name])
      if !out.nil?
        return out
      else
        raise AIXLVM::LVMException.new('system error:%s' % @system.last_error)
      end
    end
  end
end
