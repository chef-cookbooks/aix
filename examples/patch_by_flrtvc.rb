# recipe example patch using flrtvc report
# This recipe is interactive

Chef::Recipe.send(:include, AIX::PatchMgmt)

puts '#########################################################'
puts 'Available machines and their corresponding oslevel are:'
puts clients_and_vios(node)
puts 'Choose one or more (comma or space separated) to update?'
client = STDIN.readline.chomp

aix_flrtvc 'patch aix machine(s)' do
  targets client
  action [:install, :patch]
  # csv '/apar.csv'
  # apar 'all'
  # path '/flrtvc'
  # verbose true
  # clean false
  # check_only true
  # download_only true
end

# aix_nim 'reboot aix machine(s)' do
  # targets client
  # action :reboot
# end

