
node.default['nim']['clients'] = {'client1'=>{'mllevel'=>'7100-09'}}

# Suma error 6 
aix_suma "Suma with time-out" do
  oslevel   '7100-10-00'
  location  '/tmp/img.source'
  targets   'client1'
  timeout   5
  action    :download
end
