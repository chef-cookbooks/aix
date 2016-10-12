# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/oslevel/latest1/7100-02-08-1316
# suma metadata : FAKE SUMA Metadata return 7100-02-08-1316
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma 'Downloading latest SP for highest TL' do
  oslevel   'laTEst'
  location  '/sumatest/oslevel/latest1'
  targets   'client1'
  action    :download
end
