# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/oslevel/tl3/7100-03-00-0000
# suma metadata :
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM Define

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma 'Downloading TL 7100-03-00-0000' do
  oslevel   '7100-03-00-0000'
  location  '/sumatest/oslevel/tl3'
  targets   'client1'
  action    :download
end
