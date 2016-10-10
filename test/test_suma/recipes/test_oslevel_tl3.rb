# Expected values
# return code : 0
# exception : nil
# suma directory : […]
# suma metadata : […]
# suma preview : […]
# suma download : […]
# nim define : […]


node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma '15. Downloading TL 7100-05-00-0000' do
  oslevel   '7100-05-00-0000'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
