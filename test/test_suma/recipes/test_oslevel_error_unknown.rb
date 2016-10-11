# Expected values
# return code : 1
# exception : InvalidOsLevelProperty
# suma directory : 
# suma metadata : 
# suma preview : 
# suma download : 
# nim define : 


node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma 'Unknown property oslevel (ERROR)' do
  oslevel   'xxx'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
