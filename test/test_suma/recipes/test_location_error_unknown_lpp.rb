# Expected values
# return code : 1
# exception : InvalidLocationProperty
# suma directory :
# suma metadata :
# suma preview :
# suma download :
# nim define :

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }
node.default['nim']['lpp_sources'] = { 'my_beautiful_lpp-source' => { 'location' => '/usr/sys/inst.images/beautiful' } }

aix_suma 'Provide unknown lpp source as location (ERROR)' do
  oslevel   '7100-02-02-1316'
  location  'unknown_lpp-source'
  targets   'client1'
  action    :download
end
