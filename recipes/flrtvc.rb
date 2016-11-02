# recipe example flrtvc script on nim clients
# This recipe is interactive

# Default
client = Mixlib::ShellOut.new("lsnim -t standalone | cut -d' ' -f1 | sort").run_command.stdout.split
live_stream = true

puts '#########################################################'
puts 'Available machines are:'
puts client.join("\n").to_s
puts 'Choose one or more (comma-separated) to update ?'
client = STDIN.readline.chomp.split

puts '#########################################################'
puts 'Execute flrtvc.ksh with live stream (or else save to file) ? (yes/no)'
live_stream = (STDIN.readline.chomp == 'no') ? false : true

puts '#########################################################'
puts 'Select type of APAR ? (sec/hiper/both)'
apar = STDIN.readline.chomp
apar_s = (apar =~ /(both|)/) ? '' : "-t #{apar}"

##################
# PRE-REQUISITES #
##################

cmd = Mixlib::ShellOut.new('which unzip')
cmd.run_command
cmd.valid_exit_codes = 0
unless cmd.error?
  # download unzip
  remote_file "#{Chef::Config[:file_cache_path]}/unzip-6.0-3.aix6.1.ppc.rpm" do
    source 'https://public.dhe.ibm.com/aix/freeSoftware/aixtoolbox/RPMS/ppc/unzip/unzip-6.0-3.aix6.1.ppc.rpm'
  end

  # install unzip
  execute "rpm -i #{Chef::Config[:file_cache_path]}/unzip-6.0-3.aix6.1.ppc.rpm" do
  end
end

unless ::File.exist?('/usr/bin/flrtvc.ksh')
  # download flrtvc
  remote_file "#{Chef::Config[:file_cache_path]}/FLRTVC-0.7.zip" do
    source 'https://www-304.ibm.com/webapp/set2/sas/f/flrt3/FLRTVC-0.7.zip'
  end

  # unzip flrtvc
  execute "unzip #{Chef::Config[:file_cache_path]}/FLRTVC-0.7.zip -d /usr/bin" do
  end
end

# set execution mode
file '/usr/bin/flrtvc.ksh' do
  mode '0755'
end

#############################
# LOOP THROUGH CLIENT  LIST #
#############################

client.each do |c|
  file "#{c}_lslpp.txt" do
    action :nothing
  end

  file "#{c}_emgr.txt" do
    action :nothing
  end

  # execute lslpp -Lcq
  execute "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{c} \"/usr/bin/lslpp -Lcq\" > #{c}_lslpp.txt" do
    notifies :delete, "file[#{c}_lslpp.txt]", :delayed
    ignore_failure true
  end

  # execute emgr -lv3
  execute "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{c} \"/usr/sbin/emgr -lv3\" > #{c}_emgr.txt" do
    notifies :delete, "file[#{c}_emgr.txt]", :delayed
    ignore_failure true
  end

  # execute flrtvc script
  if live_stream
    execute "/usr/bin/flrtvc.ksh -v -l #{c}_lslpp.txt -e #{c}_emgr.txt #{apar_s}" do
      live_stream live_stream
      ignore_failure true
    end
  else
    execute "/usr/bin/flrtvc.ksh -v -l #{c}_lslpp.txt -e #{c}_emgr.txt #{apar_s} > #{c}_flrtvc.txt" do
      ignore_failure true
    end
  end
end
