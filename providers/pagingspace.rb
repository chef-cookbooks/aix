#
# Copyright:: 2016, Benoit Creau <benoit.creau@chmod666.org>
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

use_inline_resources # ~FC113

# support whyrun
def whyrun_supported?
  true
end

# loading current resource
def load_current_resource
  @current_resource = new_resource.class.new(@new_resource.name)

  lsps = shell_out("lsps -ca | grep ^#{@new_resource.name}")
  # lsps.error!
  # not fatal if paging space does not exists
  # Chef::Log.fatal('pagingspace: error while running lsps') unless lsps.exitstatus

  if lsps.stdout.lines.count != 1
    @current_resource.exists = false
  else
    @current_resource.exists = true
    lsps.stdout.each_line do |line|
      line_array = line.split(':')
      # if the name of the paging space exists the resource exists
      @current_resource.exists = true if line_array[0] == @new_resource.name
      # name:Pvname:Vgname:Size:Used:Active:Auto:Type:Chksum
      # hd6:hdisk0:rootvg:8:1:y:n:lv:0
      # first line of lsps -ac is a commentary
      if line_array[0] =~ /^#/
        Chef::Log.debug('pagingspace: first line of lsps -ac, skipping')
      else
        # updating current resource with current values
        @current_resource.name   = line_array[0]
        @current_resource.pvname = line_array[1]
        @current_resource.vgname = line_array[2]
        # number of pp
        @current_resource.size   = line_array[3].to_i
        # %user cannot be change skipping
        # @current_resource.used   = line_array[4]
        # active parameter
        # y = true, n = false
        if line_array[5] == 'y'
          @current_resource.active = true
        elsif line_array[5] == 'n'
          @current_resource.active = false
        end
        # auto parameter
        # y = true, n = false
        if line_array[6] == 'y'
          @current_resource.auto  = true
        elsif line_array[6] == 'n'
          @current_resource.auto  = false
        end
        # maybe needed later
        # @current_resource.type   = line_array[7]
        # @current_reousrce.chksum = line_array[8]
      end
    end
  end
end

# changing paging space
action :change do
  if @current_resource.exists
    converge = false
    chps_flag = ''
    ctrl_swap_cmd = ''
    Chef::Log.debug("pagingspace: paging space #{@current_resource.name} exits")
    # size
    unless @new_resource.size.nil?
      # finding pp size
      pp_size_cmd = shell_out!("lsvg #{@current_resource.vgname} | awk '$4 == \"PP\" {print $6}'")
      pp_size = pp_size_cmd.stdout.chomp.to_i
      # lsps -ac gives a size in pp we need a size in mb
      @current_resource.size = @current_resource.size * pp_size
      Chef::Log.debug("pagingspace: pp size of vg #{@current_resource.vgname} is #{pp_size} MB")
      Chef::Log.debug("pagingspace: acutal paging space #{@current_resource.name} size #{@current_resource.size} MB")
      Chef::Log.debug("pagingspace: new paginig space #{@current_resource.name} size will be #{@current_resource.size} MB")
      # getting number of pp to add or remove from the paging space
      # adding pp
      if @current_resource.size < @new_resource.size
        Chef::Log.debug('pagingspace: extending')
        chps_flag = '-s '
      # removing pp
      elsif @current_resource.size > @new_resource.size
        Chef::Log.debug('pagingspace: reducing')
        chps_flag = '-d '
      end
      additionnal_mb = @new_resource.size - @current_resource.size
      # we need the absolute value if reducing the paging space
      additionnal_mb = additionnal_mb.abs
      additionnal_pp = additionnal_mb.to_i / pp_size.to_f
      additionnal_pp = additionnal_pp.ceil unless additionnal_pp.is_a? Integer
      Chef::Log.debug("pagingspace: adding/removing #{additionnal_pp} to paging space")
      # converging only if we need to add or remove some pp from the paging space
      if additionnal_pp.to_i > 0
        chps_flag = chps_flag << additionnal_pp.to_s
        converge = true
      end
    end
    # if auto
    unless @new_resource.auto.nil?
      if @new_resource.auto
        Chef::Log.debug('pagingspace: auto y')
        auto = 'y'
      else
        Chef::Log.debug('pagingspace: auto n')
        auto = 'n'
      end
      if @current_resource.auto != @new_resource.auto
        converge = true
        chps_flag = chps_flag << ' -a ' << auto
      end
    end
    # if active
    unless @new_resource.active.nil?
      if @new_resource.active
        Chef::Log.debug('pagingspace: using swapon')
        ctrl_swap_cmd = 'swapon /dev/' << @current_resource.name
      else
        Chef::Log.debug('pagingspace: using swapoff')
        ctrl_swap_cmd = 'swapoff /dev/' << @current_resource.name
      end
      Chef::Log.debug("pagingspace: current active: #{@current_resource.active}, new active: #{@new_resource.active}")
      if @current_resource.active != @new_resource.active
        converge = true
      else
        ctrl_swap_cmd = ''
      end
    end
    if converge
      converge_by("paging_space: changing paging space #{@current_resource.name}") do
        chps_string = 'chps '
        chps_string = chps_string << chps_flag << ' ' << @new_resource.name
        Chef::Log.debug("pagingspace: command: #{chps_string}")
        shell_out!(chps_string)
        unless ctrl_swap_cmd.empty?
          Chef::Log.debug("pagingspace: command: #{ctrl_swap_cmd}")
          shell_out!(ctrl_swap_cmd)
        end
      end
    end
  end
end

# removing paging space
action :remove do
  if @current_resource.exists
    rmps_string = 'rmps ' << @new_resource.name
    converge_by("pagingspace: removing paging sapce #{@new_resource.name}") do
      shell_out!(rmps_string)
    end
  end
end

# creating paging space
action :create do
  # Creating paging space only if this one does not exists
  unless @current_resource.exists
    # finding pp size
    pp_size_cmd = shell_out!("lsvg #{@new_resource.vgname} | awk '$4 == \"PP\" {print $6}'")
    pp_size = pp_size_cmd.stdout.chomp.to_i
    number_of_pp = @new_resource.size / pp_size
    number_of_pp = number_of_pp.ceil
    mkps_flag = ''
    Chef::Log.debug("pagingspace: pp size of vg #{@new_resource.vgname} is #{pp_size} MB")
    Chef::Log.debug("pagingspace: paging space #{@new_resource.name} size in pp will be #{number_of_pp}")
    unless @new_resource.auto.nil?
      if @new_resource.auto
        Chef::Log.debug("pagingspace: paging space #{@new_resource.name} will be activated at reboot")
        mkps_flag = mkps_flag << ' -a '
      end
    end
    unless @new_resource.active.nil?
      if @new_resource.active
        Chef::Log.debug("pagingspace: paging space #{@new_resource.name} will be active now")
        mkps_flag = mkps_flag << ' -n '
      end
    end
    mkps_flag = mkps_flag << ' -s ' << number_of_pp.to_s << ' ' << @new_resource.vgname
    converge_by("pagingspace: creating paging space #{@new_resource.name}") do
      mkps_string = 'mkps ' << mkps_flag
      Chef::Log.debug("pagingspace: #{mkps_string}")
      mkps = shell_out!(mkps_string)
      old_name = mkps.stdout.chomp
      Chef::Log.debug("pagingspace: old_name #{old_name} new_name #{@new_resource.name}")
      # rename only if name are different
      if old_name != @new_resource.name
        shell_out!('chlv -n ' << @new_resource.name << ' ' << old_name)
        shell_out!("chps -ay #{@new_resource.name}") if @new_resource.auto
      end
    end
  end
end
