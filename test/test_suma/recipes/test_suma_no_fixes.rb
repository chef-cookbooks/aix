# Expected values
# return code : 0
# exception : nil
# suma directory : […]
# suma metadata : […]
# suma preview : […]
# suma download : […]
# nim define : […]


node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma '45. error no fixes 0500-035 (Preview only)' do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/45/'
  targets   'client1'
  action    :download
end
