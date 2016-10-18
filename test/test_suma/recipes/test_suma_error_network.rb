# Expected values
# return code : 1
# exception : SumaPreviewError
# suma directory : /sumatest/suma/error1/7100-02-02-1316-lpp_source
# suma metadata :
# suma preview : ### SUMA FAKE Preview ERROR ###
# suma download :
# nim define :

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01-1316' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Error network 0500-013 (Preview ERROR)' do
  oslevel   '7100-02-02-1316'
  location  '/sumatest/suma/error1'
  targets   'client1'
  action    :download
end
