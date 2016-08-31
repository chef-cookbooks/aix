
node.default['nim']['clients'] = {'client1'=>{'oslevel'=>'7100-09'}}

# Suma error 2
aix_suma "error network for test" do
  oslevel   '7100-09-01'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
