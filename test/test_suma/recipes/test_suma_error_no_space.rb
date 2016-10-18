# Expected values
# return code : 1
# exception : SumaDownloadError
# suma directory : /sumatest/suma/error3/7100-02-02-1316-lpp_source
# suma metadata :
# suma preview : ### SUMA FAKE Preview ###
# suma download : ### SUMA FAKE Download ERROR ###
# nim define :

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01-1316' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Error no more space 0500-004 (Download ERROR)' do
  oslevel   '7100-02-02-1316'
  location  '/sumatest/suma/error3'
  targets   'client1'
  action    :download
end
