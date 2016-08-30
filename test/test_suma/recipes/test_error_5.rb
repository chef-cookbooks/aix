
node.default['nim']['clients'] = {'client1'=>{'mllevel'=>'7100-09'}}

# Suma error 5 
aix_suma "Suma with oslevel wrong" do
  oslevel   '7100-aa-bb'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
