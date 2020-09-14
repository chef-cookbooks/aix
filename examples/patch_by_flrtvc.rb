# recipe example patch using flrtvc report
# This recipe is interactive

Chef::DSL::Recipe.include AIX::PatchMgmt

puts '#########################################################'
puts 'Available machines and their corresponding oslevel are:'
puts clients_and_vios(node)
puts 'Choose one or more (comma or space separated) to update?'
client = STDIN.readline.chomp

aix_flrtvc 'patch aix machine(s)' do
  targets client
  action [:install, :patch]
  apar 'all'
  path '/flrtvc'
  verbose true
  clean true
  check_only false
  download_only false
end
