# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/oslevel/sp2/7100-02-02-1316
# suma metadata : FAKE SUMA Metadata return 7100-02-02-1316
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM Define

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma 'Downloading SP 7100-02-02' do
  oslevel   '7100-02-02'
  location  '/sumatest/oslevel/sp2'
  targets   'client1'
  action    :download
end
