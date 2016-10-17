# Expected values
# return code : 1
# exception : InvalidLocationProperty
# suma directory :
# suma metadata :
# suma preview :
# suma download :
# nim define :

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }
node.default['nim']['lpp_sources'] = { '7100-02-02-1316-lpp_source' => { 'location' => '/usr/sys/inst.images/7100-02-02-1316-lpp_source' } }

aix_suma 'Existing lpp source but different location (ERROR)' do
  oslevel   '7100-02-02-1316'
  location  '/sumatest/location/dir2'
  targets   'client1'
  action    :download
end
