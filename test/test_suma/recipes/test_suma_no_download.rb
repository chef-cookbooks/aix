node.default['nim']['clients'] = {'client1'=>{'oslevel'=>'7100-02-01'}}

aix_suma "46. nothing to download (Preview only)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/46/'
  targets   'client1'
  action    :download
end