# Expected values
# return code : 1
# exception : InvalidOsLevelProperty
# suma directory : /sumatest/oslevel/error
# suma metadata :
# suma preview :
# suma download :
# nim define :

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Unknown property oslevel (ERROR)' do
  oslevel   'xxx'
  location  '/sumatest/oslevel/error'
  targets   'client1'
  action    :download
end
