File.foreach('/etc/hosts') do |line|
  raise 'ERROR: Test IP addresses found in /etc/hosts. Aborting to prevent changes.' if line =~ /^1.1.1.[0123456]/
  raise 'ERROR: Test hostnames found in /etc/hosts. Aborting to prevent changes.' if line =~ /test[123456]/
end

aix_etchosts 'test1' do
  ip_address '1.1.1.1'
  action :add
end

aix_etchosts 'test2.0' do
  ip_address '1.1.1.2'
  aliases ['test2.1', 'test2.2']
  action :add
end

aix_etchosts 'test3_setup' do
  name 'test3'
  ip_address '1.1.1.0'
  action :add
end

aix_etchosts 'test3' do
  ip_address '1.1.1.3'
  action :change
end

aix_etchosts 'test4_setup' do
  name 'test4.0'
  ip_address '1.1.1.4'
  action :add
end

aix_etchosts 'test4.0' do
  new_hostname 'test4.1'
  action :change
end

aix_etchosts 'test5_setup' do
  name 'test5.0'
  ip_address '1.1.1.5'
  action :add
end

aix_etchosts '1.1.1.5' do
  aliases ['test5.0', 'test5.1']
  action :change
end

aix_etchosts '1.1.1.6' do
  aliases ['test6.0', 'test6.1']
  action [:add, :change]
end

aix_etchosts '1.1.1.1' do
  action :delete
end

aix_etchosts '1.1.1.2' do
  action :delete
end

aix_etchosts '1.1.1.3' do
  action :delete
end

aix_etchosts '1.1.1.4' do
  action :delete
end

aix_etchosts '1.1.1.5' do
  action :delete
end

aix_etchosts '1.1.1.6' do
  action :delete
end
