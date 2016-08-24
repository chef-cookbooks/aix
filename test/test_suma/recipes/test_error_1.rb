
node.default['nim']['clients'] = {'client1'=>{'oslevel'=>'7100-09-00'}}

# Suma error 1 
aix_suma "error network (BSO) for test" do
  name      '7100-09-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
