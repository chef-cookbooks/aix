# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/suma/define1/7100-02-02-1316
# suma metadata :
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM Define

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma 'LPP source absent (Preview + Download + Define)' do
  oslevel   '7100-02-02-1316'
  location  '/sumatest/suma/define1'
  targets   'client1'
  action    :download
end
