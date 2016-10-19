# recipe example flrtvc script on nim clients
# This recipe is interactive

=begin
Chef::Recipe.send(:include, AIX::PatchMgmt)

nodes = Hash.new { |h, k| h[k] = {} }
nodes['machine'] = node['nim']['clients'].keys
nodes['oslevel'] = node['nim']['clients'].values.collect { |m| m.fetch('oslevel', nil) }
nodes['Cstate'] = node['nim']['clients'].values.collect { |m| m.fetch('lsnim', {}).fetch('Cstate', nil) }

puts '#########################################################'
puts 'Available machines and their corresponding oslevel are:'
puts print_hash_by_columns(nodes)
puts 'Choose one or more (comma-separated) to update ?'
client = STDIN.readline.chomp
=end

client = 'quimby03 quimby02'

##################
# PRE-REQUISITES #
##################

# download unzip
remote_file '/tmp/unzip-6.0-3.aix6.1.ppc.rpm' do
  source 'https://public.dhe.ibm.com/aix/freeSoftware/aixtoolbox/RPMS/ppc/unzip/unzip-6.0-3.aix6.1.ppc.rpm'
  not_if 'which unzip'
end

# install unzip
execute 'rpm -i /tmp/unzip-6.0-3.aix6.1.ppc.rpm' do
  not_if 'which unzip'
end

# download flrtvc
remote_file '/tmp/FLRTVC-0.7.zip' do
  source 'https://www-304.ibm.com/webapp/set2/sas/f/flrt3/FLRTVC-0.7.zip'
  not_if do ::File.exist?('/usr/bin/flrtvc.ksh') end
end

# unzip flrtvc
execute 'unzip /tmp/FLRTVC-0.7.zip -d /usr/bin' do
  not_if do ::File.exist?('/usr/bin/flrtvc.ksh') end
end

# set execution mode
file '/usr/bin/flrtvc.ksh' do
  mode '0755'
end

#############################
# LOOP THROUGH CLIENT  LIST #
#############################

client.split.each do |c|
  file "#{c}_lslpp.txt" do
    action :nothing
  end

  file "#{c}_emgr.txt" do
    action :nothing
  end

  # execute lslpp -Lcq
  execute "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{c} \"/usr/bin/lslpp -Lcq\" > #{c}_lslpp.txt" do
    notifies :delete, "file[#{c}_lslpp.txt]", :delayed
  end

  # execute emgr -lv3
  execute "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{c} \"/usr/sbin/emgr -lv3\" > #{c}_emgr.txt" do
    notifies :delete, "file[#{c}_emgr.txt]", :delayed
  end

  # execute flrtvc script
  execute "/usr/bin/flrtvc.ksh -l lspp.txt -e emgr.txt > #{c}_flrtvc.txt" do
  end
end
