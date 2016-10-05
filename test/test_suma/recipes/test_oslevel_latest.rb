node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma '16. Downloading latest SP for highest TL' do
  oslevel   'laTEst'
  location  '/tmp/img.source/latest1'
  targets   'client1'
  action    :download
end
