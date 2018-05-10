# recipe example setup nim master
# Assume that the 'nim_server' is the hostname of the current nim server
# and the 'new_nim_server' is the hostname of the nim master to setup
nim_server = 'pollux6'
lpp_source = '1626A_72D_lpp'
new_nim_server = 'pollux6c'

nim_script_res_name  = "chef_nim_setup_script_#{new_nim_server}"
nim_script_file_name = "/tmp/#{nim_script_res_name}.sh"
mount_point = '/mnt_chef_master_setup'

cmd = Mixlib::ShellOut.new("lsnim -l #{lpp_source} | grep location | awk '{ print $NF }'")
cmd.run_command
cmd.valid_exit_codes = 0
if cmd.error?
end
nim_res_path = cmd.stdout.chomp

# Create the script to set the new nim master.
file nim_script_file_name do
  content "#!/bin/ksh\nexport LANG=C\nmkdir #{mount_point}\nmount #{nim_server}:#{nim_res_path} #{mount_point}\nnim_master_setup -a mk_resource=no -B -a device=#{mount_point}\numount #{mount_point}\nrmdir #{mount_point}\n"
  mode '0777'
  owner 'root'
  action :create
end

# Define the script nim resource
aix_nim 'define_script_resource' do
  resource nim_script_res_name
  location nim_script_file_name
  action :define_script
end

# Allocate the required lpp_source
aix_nim 'Allocate lpp_source' do
  lpp_source lpp_source
  targets new_nim_server
  action :allocate
end

# Export the resources
execute 'export_res' do
  command 'exportfs'
  action :run
end

# Setup the nim master
aix_nim 'setup_master' do
  script nim_script_res_name
  targets new_nim_server
  async false
  action :script
end

# Deallocate the resource on the old nim server
aix_nim 'Deallocate lpp_source' do
  lpp_source lpp_source
  targets new_nim_server
  action :deallocate
end

# Remove the script resource
aix_nim 'remove_script_resource' do
  resource nim_script_res_name
  action :remove
end

# Remove the script file
file nim_script_file_name do
  action :delete
end
