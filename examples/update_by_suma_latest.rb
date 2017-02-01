# recipe example update to latest sp or tl using suma and nim
# This recipe is interactive

Chef::Recipe.send(:include, AIX::PatchMgmt)

puts '#########################################################'
puts 'Available machines and their corresponding oslevel are:'
puts clients(node)
puts 'Choose one or more (comma or space separated) to update?'
client = STDIN.readline.chomp

puts '#########################################################'
puts 'Where to download? (default to /export/extra/lpp_source)'
directory = STDIN.readline.chomp
directory = '/export/extra/lpp_source' if directory.empty?

ohai 'reload_nim' do
  action :nothing
  plugin 'nim'
end

aix_suma "Downloading latest installation images to '#{directory}'" do
  location directory
  targets client
  action :download
  notifies :reload, 'ohai[reload_nim]', :immediately
end

aix_nim "Updating machine(s) '#{client}'" do
  lpp_source 'latest_sp'
  targets client
  async true
  action [:update, :reboot]
  ignore_failure true
end
