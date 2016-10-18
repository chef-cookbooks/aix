# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/suma/download1/7100-02-02-1316-lpp_source
# suma metadata :
# suma preview : ### SUMA FAKE Preview ###
# suma download : ### SUMA FAKE Download ###
# nim define :

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01-1316' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Failed fixes (Preview + Download)' do
  oslevel   '7100-02-02-1316'
  location  '/sumatest/suma/download1'
  targets   'client1'
  action    :download
end
