# recipe example update using suma and nim
# This recipe is interactive and allows upgrade of AIX 7.1 and 7.2 machines

Chef::Recipe.include AIX::PatchMgmt

puts '#########################################################'
puts 'Available machines and their corresponding oslevel are:'
puts clients(node)
puts 'Choose one or more (comma or space separated) to update?'
client = STDIN.readline.chomp

puts '#########################################################'
puts 'Available SP/TL levels are:'
puts levels(node)
puts 'Choose one to download and install?'
level = STDIN.readline.chomp

puts '#########################################################'
puts 'Where to download? (default to /usr/sys/inst.images)'
directory = STDIN.readline.chomp
directory = '/usr/sys/inst.images' if directory.empty?

ohai 'reload_nim' do
  action :nothing
  plugin 'nim'
end

aix_suma "Downloading '#{level}' installation images to '#{directory}'" do
  oslevel level
  location directory
  targets client
  action :download
  notifies :reload, 'ohai[reload_nim]', :immediately
end

aix_nim "Updating machine(s) '#{client}'" do
  lpp_source "#{level}-lpp_source"
  targets client
  async false
  action [:update, :reboot]
  only_if "lsnim -t lpp_source #{level}-lpp_source"
  notifies :reload, 'ohai[reload_nim]', :immediately
  ignore_failure true
end

aix_nim 'Check update status' do
  action :check
end
