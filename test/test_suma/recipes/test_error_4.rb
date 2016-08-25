
node.default['nim']['clients'] = {}

# Suma error 4 
aix_suma "Suma with client unknown" do
  name      '7100-09-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
