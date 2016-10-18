# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/suma/preview1/7100-02-02-1316
# suma metadata :
# suma preview : FAKE SUMA Preview
# suma download :
# nim define :

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01-1316' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Error no fixes 0500-035 (Preview only)' do
  oslevel   '7100-02-02-1316'
  location  '/sumatest/suma/preview1'
  targets   'client1'
  action    :download
end
