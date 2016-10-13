# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/suma/download2/7100-02-02-1316'
# suma metadata :
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define :

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'LPP source exists (Preview + Download)' do
  oslevel   '7100-02-02-1316'
  location  'sumatest/suma/download2'
  targets   'client1'
  action    :download
end
