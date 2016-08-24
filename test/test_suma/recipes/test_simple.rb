
node.default['nim']['clients'] = {'client1'=>{'oslevel'=>'7100-09-00'},'client2'=>{'oslevel'=>'7100-10-05'},'client3'=>{'oslevel'=>'7100-08-04'}}

# Suma simple LT
aix_suma "Downloading LT 7100-09-00 >> 7100-09-02" do
  name      '7100-09-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

# Suma simple SP
aix_suma "Downloading SP 7100-09-00 >> 7100-10-00" do
  name      '7100-10-00'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

# Sumo nothing 
aix_suma "nothing 7100-10-05 >> 7100-09-03" do
  name      '7100-09-03'
  location  '/tmp/img.source'
  targets   'client2'
  action    :download
end

# Suma multi LT/SP
aix_suma "Downloading LT/SP 7100-08-04 >> 7100-10-04" do
  name      '7100-10-04'
  location  '/tmp/img.source'
  targets   'client1,client2,client3'
  action    :download
end
