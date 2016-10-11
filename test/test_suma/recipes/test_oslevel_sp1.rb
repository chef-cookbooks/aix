# Expected values
# return code : 0
# exception : nil
# suma directory : /tmp/img.source
# suma metadata : { 'client1' => { 'oslevel' => '7100-02-01' } }
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM


node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma 'Downloading SP 7100-02-02' do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
