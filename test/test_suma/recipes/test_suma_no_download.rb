# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/suma/preview2/7100-02-02-1316-lpp_source
# suma metadata :
# suma preview : ### SUMA FAKE Preview ###
# suma download :
# nim define :

node.default['nim']['master'] = { 'oslevel' => '7100-02-01' }
node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01-1316' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Nothing to download (Preview only)' do
  oslevel   '7100-02-02-1316'
  location  '/sumatest/suma/preview2'
  targets   'client1'
  action    :download
end
