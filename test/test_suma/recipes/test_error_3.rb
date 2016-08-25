
node.default['nim']['clients'] = {'client1'=>{'mllevel'=>'7100-09'}}

# Suma error 3 
aix_suma "Suma configuration: not entitled" do
  name      '7100-09-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
