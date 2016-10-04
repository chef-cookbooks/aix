# recipe example update to latest sp or tl using suma and nim
# This recipe is interactive

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

lpp_source = 'latest_sp'
directory = '/export/extra/lpp_source'

ohai 'reload_nim' do
  action :nothing
  plugin 'nim'
end

aix_suma 'Downloading latest installation images' do
  location directory
  targets client
  action :download
  notifies :reload, 'ohai[reload_nim]', :immediately
end

aix_nim "Updating machine(s) #{client}" do
  lpp_source lpp_source
  targets client
  async true
  action :update
  ignore_failure true
end
