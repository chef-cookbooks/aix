# Expected values
# return code : 1
# exception : NimDefineError
# suma directory : /sumatest/suma/error4/7100-02-02-1316
# suma metadata :
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM Define Error 1

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma 'Error nim define (Preview + Download + Define ERROR)' do
  oslevel   '7100-02-02-1316'
  location  '/sumatest/suma/error4'
  targets   'client1'
  action    :download
end
