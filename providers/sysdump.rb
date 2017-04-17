require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

use_inline_resources
# support whyrun
def whyrun_supported?
  true
end

# loading current resource
def load_current_resource
  @current_resource = Chef::Resource::AixSysdump.new(@new_resource.name)

  sysdumpdev = shell_out("sysdumpdev -l")

  sysdumpdev.stdout.each_line do |a_line|
    if a_line.split(" ")[0] == "primary"
      @current_resource.primary_device(a_line.split(" ")[1].lstrip.chomp)
      Chef::Log.debug("sysdump: current primary dump device is set to #{@current_resource.primary_device}")
    elsif a_line.split(" ")[0] == "secondary"
      @current_resource.secondary_device(a_line.split(" ")[1].lstrip.chomp)
      Chef::Log.debug("sysdump: current secondary dump device is set to #{@current_resource.secondary_device}")
    end
  end
end

action :change do
  command =  "sysdumpdev "
  converge=false

 ## setting permanent flag or not
  if @new_resource.permanent
    command = command << "-P "
  end

 ## if devices specified are the same, we die, except for sysdumpnull (which can be used twice)
  if @new_resource.primary_device==@new_resource.secondary_device and @new_resource.primary_device != "sysdumpnull"
    raise("sysdumpdev: primary device #{@new_resource.primary_device} and secondary #{@new_resource.secondary_device} are the same, please correct.")
  end

 ## primary dump device check, if it exists
  unless @new_resource.primary_device.nil?
    if "/dev/" << @new_resource.primary_device==@current_resource.primary_device
      Chef::Log.debug("sysdump: primary device is already set to  #{@current_resource.primary_device}")
    else
      if @new_resource.primary_device == "sysdumpnull"
        command = command << " -p /dev/" << @new_resource.primary_device << " "
        converge = true
      else
        check_cmd = "lsattr -El " << @new_resource.primary_device << "| grep sysdump"
        so = shell_out(check_cmd)
        if so.exitstatus != 0
          raise("sysdumpdev: device @new_resource.primary_device does not exist or isn't sysdump type")
        else
          command = command << " -p /dev/" << @new_resource.primary_device << " "
          converge = true
        end
      end
    end
  end

 ## secondary dump device check, if it exists
  unless @new_resource.secondary_device.nil?
    if "/dev/" << @new_resource.secondary_device==@current_resource.secondary_device
      Chef::Log.debug("sysdump: secondary device is already set to  #{@current_resource.secondary_device}")
    else
      if @new_resource.secondary_device == "sysdumpnull"
        command = command << " -s /dev/" << @new_resource.secondary_device << " "
        converge = true
      else
        check_cmd = "lsattr -El " << @new_resource.secondary_device << "| grep sysdump"
        so = shell_out(check_cmd)
        if so.exitstatus != 0
          raise("sysdumpdev: device @new_resource.secondary_device does not exist or isn't sysdump type")
        else
          command = command << " -s /dev/" << @new_resource.secondary_device << " "
          converge = true
        end
      end
    end
  end

  if converge
    converge_by("sysdump: changing dump devices, #{command}") do
      sysdump_all = Mixlib::ShellOut.new(command)
      sysdump_all.valid_exit_codes = 0
      sysdump_all.run_command
      sysdump_all.error!
      sysdump_all.error?
    end
  end
end
