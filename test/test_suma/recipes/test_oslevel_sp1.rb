node.default['nim']['clients'] = {'client1'=>{'oslevel'=>'7100-02-01'}}

aix_suma "11. Downloading SP 7100-02-02" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
