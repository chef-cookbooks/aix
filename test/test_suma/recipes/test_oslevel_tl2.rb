# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/oslevel/tl2/7100-03-00-0000
# suma metadata :
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM Define

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Downloading TL 7100-03-00' do
  oslevel   '7100-03-00'
  location  '/sumatest/oslevel/tl2'
  targets   'client1'
  action    :download
end
