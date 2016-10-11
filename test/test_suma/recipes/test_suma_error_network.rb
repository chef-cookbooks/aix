# Expected values
# return code : 0
# exception : nil
# suma directory : […]
# suma metadata : […]
# suma preview : […]
# suma download : […]
# nim define : […]


node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma 'Error network 0500-013 (Preview ERROR)' do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/42/'
  targets   'client1'
  action    :download
end
