require 'chef/mixin/shell_out'

include Chef::Mixin::ShellOut

use_inline_resources

# support whyrun
def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::AixLvmVolumeGroup.new(@new_resource.name)
  @current_resource.exists = false
  lsvg = Mixlib::ShellOut.new("lsvg #{@new_resource.name}")
  lsvg.valid_exit_codes = 0
  lsvg.run_command
  if lsvg.error?
    Chef::Log.info('mkvg: resource does not exist')
  else
    Chef::Log.info('mkvg: resource exists')
    @current_resource.exists = true
  end
end

# add
action :add do
  unless @current_resource.exists
    # Assign that disk not found by default
    disk_found = false
    mkvg = 'mkvg'

    # Valid options.  Contains logical test and option output
    option_map = {
      'big' => [(@new_resource.big), '-B'],
      'factor' => [(!@new_resource.factor.nil?), "-t #{@new_resource.factor}"],
      'scalable' => [(@new_resource.scalable), '-S'],
      'lv_number' => [(!@new_resource.lv_number.nil?) , "-v #{@new_resource.lv_number}"],
      'partitions' => [(!@new_resource.partitions.nil?), "-P #{new_resource.partitions}"],
      'powerha_concurrent' => [(@new_resource.powerha_concurrent), '-C'],
      'force' => [(@new_resource.force), '-f'],
      'pre_53_compat' => [(@new_resource.pre_53_compat), '-I'],
      'pv_type' => [(!@new_resource.pv_type.nil?), "-X#{@new_resource.pv_type}"],
      'activate_on_boot' => [(@new_resource.activate_on_boot.eql? 'no'), '-n'],
      'partition_size' => [(!@new_resource.partition_size.nil?), "-s #{@new_resource.partition_size}"],
      'major_number' => [(!@new_resource.major_number.nil?), "-V #{@new_resource.major_number}"],
      'name' => [(!@new_resource.name.empty?), "-y #{@new_resource.name}"],
      'mirror_pool_strictness' => [(!@new_resource.mirror_pool_strictness.nil?), "-M #{@new_resource.mirror_pool_strictness}"],
      'mirror_pool' => [(!@new_resource.mirror_pool.nil?), "-p #{@new_resource.mirror_pool}"],
      'infinite_retry' => [(@new_resource.infinite_retry), '-O y'],
      'non_concurrent_varyon' => [(!@new_resource.non_concurrent_varyon.nil?), "-N #{@new_resource.non_concurrent_varyon}"],
      'critical_vg' => [(@new_resource.critical_vg), 'r y']
    }
    # Assign options
    option_map.each do |_opt, val|
      mkvg =  (val[0] ? "#{mkvg} #{val[1]}" : mkvg)
    end

    # Any other options passed-in
    unless @new_resource.options.nil?
      @new_resource.options.each do |o, v|
        mkvg = mkvg << " #{o}"
        if !v.nil? || !v.empty?
          mkvg = mkvg << " #{v}"
        end
      end
    end
 
    # Select disks based on disk array attribute
    if !@new_resource.disks.nil?
      disk_found = true
      unused_disks = unused_disk_search
      @new_resource.disks.each do |thisdisk|
        # Check if disk already in use, raise if it is
        if unused_disks.include? thisdisk
          mkvg = mkvg << " #{thisdisk}"
        else
          raise "mkvg:  cannot continue, disk #{thisdisk} is in use"
        end
      end
    # Find single best-fit disk
    elsif @new_resource.best_fit > 0
      best_fit = best_fit_disk(@new_resource.best_fit)
      unless best_fit.nil?
        disk_found = true
        mkvg = mkvg << " #{best_fit}"
      end
    # Use all available disks
    elsif @new_resource.use_all_disks
      all_disks = unused_disk_search
      unless all_disks.nil?
        disk_found = true
        all_disks.each do |thisdisk|
          mkvg = mkvg << " #{thisdisk}"
        end
      end
    end

    # Perform add if disk have been selected, else raise the error
    if disk_found
      converge_by("mkvg: add #{@new_resource.name} : #{mkvg}") do
        Chef::Log.info("mkvg: creating #{@new_resource.name} : #{mkvg}")
        mkvg_add = Mixlib::ShellOut.new(mkvg)
        mkvg_add.valid_exit_codes = 0
        mkvg_add.run_command
        mkvg_add.error!
        mkvg_add.error?
      end
    else
      raise 'mkvg: no disks found for volume group creation'
    end
  end
end

action :change do
  if !@current_resource.exists
    raise "chvg: volume group #{@new_resource.name} not found"
  else
    # No updates by default
    usable_options = false
    # Gather VG information
    so = shell_out("lqueryvg -g $(getlvodm -v #{@new_resource.name}) -a | tr '\n' '|'")
    vginfo = so.stdout.split('|')
    Chef::Log.info(vginfo)
    # Command start
    chvg = 'chvg'
    # Valid options.  Contains logical test and option output
    option_map = {
      'auto_synchronize' => [(@new_resource.auto_synchronize.eql? "on") && (vginfo[16].to_s.eql? "0"), '-s y'],
      'auto_synchronize_off' => [(@new_resource.auto_synchronize.eql? "off") && (vginfo[16].to_s.eql? "1"), '-s n'],
      'hotspare_n' => [(@new_resource.hotspare.eql? "n") && (!vginfo[15].eql? "0"), "-h #{@new_resource.hotspare}"],
      'hotspare_r' => [(@new_resource.hotspare.eql? "r"), "-h #{@new_resource.hotspare}"],
      'hotspare_y' => [(@new_resource.hotspare.eql? "y") && (!vginfo[15].eql? "1"), "-h #{@new_resource.hotspare}"],
      'hotspare_Y' => [(@new_resource.hotspare.eql? "Y") && (!vginfo[15].eql? "2"), "-h #{@new_resource.hotspare}"],
      'activate_on_boot' => [(@new_resource.activate_on_boot.eql? 'yes') && (!vginfo[10].eql? '1'), '-a y'],
      'activate_on_boot_off' => [(@new_resource.activate_on_boot.eql? 'no') && (!vginfo[10].eql? '0'), '-a n'],
      'lost_quorom_varyoff_off' => [(@new_resource.lost_quorom_varyoff.eql? "no") && (!vginfo[9].eql? '0'), '-Q n'],
      'lost_quorom_varyoff_on' => [(@new_resource.lost_quorom_varyoff.eql? "yes") && (!vginfo[9].eql? '1'), '-Q y'],
      'factor' => [(!@new_resource.factor.nil?) && (!vginfo[21].eql? "2") && (!@new_resource.factor.eql?  vginfo[7].to_i / 1016), "-t #{@new_resource.factor}"],
      'big' => [(@new_resource.big) && (vginfo[21] != "1"), '-B'],
      'force' => [(@new_resource.force), '-f'],
    }
    # Assign options
    option_map.each do |_opt, val|
      if val[0]
        chvg = chvg << " #{val[1]}"
        usable_options = true
      end
    end


    # Any other options passed-in
    unless @new_resource.options.nil?
      usable_options = true
      @new_resource.options.each do |o, v|
          chvg = chvg << " #{o}"
          if !v.nil? || !v.empty?
             chvg = chvg << " #{v}"
          end
      end
    end
    

    chvg = chvg << " #{@new_resource.name}"

    # Perform chvg
    if usable_options
       converge_by("chvg: changing #{@new_resource.name} : #{chvg}") do
         Chef::Log.info("chvg: chaning #{@new_resource.name} : ${chvg}")
         chvg_do = Mixlib::ShellOut.new(chvg)
         chvg_do.valid_exit_codes = 0
         chvg_do.run_command
         chvg_do.error!
         chvg_do.error?
       end
    end
  end
end

def best_fit_disk(size)
  # Nil by default
  disk = nil
  # Get unused disk array
  unused_disks = unused_disk_search
  Chef::Log.info("unused disks: #{unused_disks}")
  # Interate through array to find size of disk, keep if larger than size requested
  unless unused_disks.nil?
    disk_choices = {}
    unused_disks.each do |this_disk|
      disk_name = this_disk
      Chef::Log.info("mkvg: examining disk size for #{this_disk}")
      disksize = Mixlib::ShellOut.new("getconf DISK_SIZE /dev/#{this_disk}")
      disksize.run_command
      disk_size = disksize.stdout.to_i / 1024
      if disk_size >= size
        disk_choices[disk_name] = disk_size
      end
    end
    Chef::Log.info("mkvg: disk sizes: #{disk_choices}")
    disk_chosen = disk_choices.min_by { |_k, v| v }
    Chef::Log.info("mkvg: disk chosen: #{disk_chosen}")
    unless disk_chosen.nil?
      disk = disk_chosen[0]
    end
  end
  disk
end

def unused_disk_search
  # Find unused disk and put into array
  unused_disk = Mixlib::ShellOut.new("lspv |awk '$3 == \"None\" {printf \"%s \",$1}'")
  unused_disk.run_command
  unused_disk_array = unused_disk.stdout.split(' ')
  unused_disk_array
end
