# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/oslevel/latest1/7100-02-08-1316-lpp_source
# suma metadata : FAKE SUMA Metadata return 7100-02-08-1316
# suma preview : ### SUMA FAKE Preview ###
# suma download : ### SUMA FAKE Download ###
# nim define : ### NIM FAKE Define ###

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Downloading latest SP for highest TL' do
  oslevel   'laTEst'
  location  '/sumatest/oslevel/latest1'
  targets   'client1'
  action    :download
end
