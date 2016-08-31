
node.default['nim']['clients'] = {'client1'=>{'oslevel'=>'7100-09'},'client2'=>{'oslevel'=>'7100-10'},'client3'=>{'oslevel'=>'7100-08'}}

aix_suma "Downloading SP 7100-09 >> 7100-09-02" do
  oslevel   '7100-09-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma "Downloading TL+SP 7100-09 >> 7100-10-02" do
  oslevel   '7100-10-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma "nothing 7100-10 >> 7100-09-03" do
  oslevel   '7100-09-03'
  location  '/tmp/img.source'
  targets   'client2'
  action    :download
end

aix_suma "Downloading multi-clients TL+SP 7100-08 >> 7100-10-04" do
  oslevel   '7100-10-04'
  location  '/tmp/img.source'
  targets   'client1,client2,client3'
  action    :download
end
