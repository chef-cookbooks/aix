# Expected values
# return code : 0
# exception : nil
# suma directory : /tmp/img.source
# suma metadata : 
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM


node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma 'Downloading TL 7100-05-00-0000' do
  oslevel   '7100-05-00-0000'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
