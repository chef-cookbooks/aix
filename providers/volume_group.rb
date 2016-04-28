require 'chef/mixin/shell_out'

include Chef::Mixin::ShellOut

include Opscode::AixLvm::Helpers

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
      'big' => [@new_resource.big, '-B'],
      'factor' => [@new_resource.factor > 0, " -t #{@new_resource.factor}"],
      'scalable' => [@new_resource.scalable, '-S'],
      'lv_number' => [ @new_resource.lv_number > 0, "-v #{@new_resource.lv_number}"],
      'partitions' => [@new_resource.partitions > 0, "-P #{new_resource.partitions}"],
      'powerha_concurrent' => [@new_resource.powerha_concurrent, '-C'],
      'force' => [@new_resource.force, '-f'],
      'pre_53_compat' => [@new_resource.pre_53_compat, '-I'],
      'pv_type' => [!@new_resource.pv_type.empty?, "-X#{@new_resource.pv_type}"],
      'activate_on_boot' => [!@new_resource.activate_on_boot,  '-n'],
      'partition_size' => [@new_resource.partition_size > 0,  "-s #{@new_resource.partition_size}"],
      'major_number' => [@new_resource.major_number > 0, "-V #{@new_resource.major_number}"],
      'name' => [!@new_resource.name.empty?,  "-y #{@new_resource.name}"],
      'mirror_pool_strictness' => [!@new_resource.mirror_pool_strictness.empty?, "-M #{@new_resource.mirror_pool_strictness}"],
      'mirror_pool' => [!@new_resource.mirror_pool.empty?,  "-p #{@new_resource.mirror_pool}"],
      'infinite_retry' => [@new_resource.infinite_retry,  '-O y'],
      'non_concurrent_varyon' => [!@new_resource.non_concurrent_varyon.empty?,  "-N #{@new_resource.non_concurrent_varyon}"],
      'critical_vg' => [@new_resource.critical_vg, 'r y']
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
    # Command start
    chvg = 'chvg'
    # Valid options.  Contains logical test and option output
    option_map = {
      'auto_synchronize' => [@new_resource.auto_synchronize,  '-s y'],
      'hotspare' => [!@new_resource.hotspare.empty?,  "-h Hotspare #{@new_resource.hotspare}"],
      'activate_on_boot' => [!@new_resource.activate_on_boot,  '-a AutoOn n'],
      'make_non_concurrent' => [@new_resource.make_non_concurrent, '-l'],
      'lost_quorom_varyoff' => [!@new_resource.lost_quorom_varyoff,  '-Q n'],
      'pv_type' => [!@new_resource.pv_type.empty?,  "-X#{@new_resource.pv_type}"],
      'drain_io' => [@new_resource.drain_io, '-S'],
      'resume_io' => [@new_resource.resume_io, '-R'],
      'factor' => [@new_resource.factor > 0,  "-t #{@new_resource.factor}"],
      'big' => [@new_resource.big, '-B'],
      'scalable' => [@new_resource.scalable, '-G'],
      'partitions' => [@new_resource.partitions > 0,  "-P #{new_resource.partitions}"],
      'lv_number' => [@new_resource.lv_number > 0,  "-v #{@new_resource.lv_number}"],
      'powerha_concurrent' => [@new_resource.powerha_concurrent, '-C'],
      'force' => [@new_resource.force, '-f'],
      'grow' => [@new_resource.grow,  '-g'],
      'bad_block_relocation' => [!@new_resource.bad_block_relocation,  '-b n'],
      'mirror_pool_strictness' => [!@new_resource.mirror_pool_strictness.empty?, "-M #{@new_resource.mirror_pool_strictness}"],
      'jfs2_resync_only' => [@new_resource.jfs2_resync_only, '-j y']
    }
    # Assign options
    option_map.each do |_opt, val|
      chvg =  (val[0] ? "#{chvg} #{val[1]}" : chvg)
    end


    # Any other options passed-in
    unless @new_resource.options.nil?
      @new_resource.options.each do |o, v|
        chvg = chvg << " #{o}"
        if !v.nil? || !v.empty?
          chvg = chvg << " #{v}"
        end
      end
    end

    chvg = chvg << " #{@new_resource.name}"

    # Perform chvg
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
