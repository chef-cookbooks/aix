# Expected values
# return code : 0
# exception : nil
# suma directory : /tmp/img.source/latest2
# suma metadata : 
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM


node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma 'Default property oslevel (latest)' do
  # oslevel 'latest'
  location  '/tmp/img.source/latest2'
  targets   'client1'
  action    :download
end
