node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma '49. lpp source absent (Preview + Download + Define)' do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/49/'
  targets   'client1'
  action    :download
end
