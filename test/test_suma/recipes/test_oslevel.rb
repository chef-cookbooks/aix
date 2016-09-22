node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma '11. Downloading SP 7100-02-02' do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma '12. Downloading SP 7100-02-03-1316' do
  oslevel   '7100-02-03-1316'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma '13. Downloading TL 7100-03' do
  oslevel   '7100-03'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma '14. Downloading TL 7100-04-00' do
  oslevel   '7100-04-00'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma '15. Downloading TL 7100-05-00-0000' do
  oslevel   '7100-05-00-0000'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma '16. Downloading latest SP for highest TL' do
  oslevel   'laTEst'
  location  '/tmp/img.source/latest1'
  targets   'client1'
  action    :download
end

aix_suma '17. Default property oslevel (latest)' do
  # oslevel	'latest'
  location  '/tmp/img.source/latest2'
  targets   'client1'
  action    :download
end

aix_suma '18. Empty property oslevel (latest)' do
  oslevel   ''
  location  '/tmp/img.source/latest3'
  targets   'client1'
  action    :download
end
