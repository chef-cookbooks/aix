
node.default['nim']['clients'] = {}

# Suma error 4 
aix_suma "Suma with client unknown" do
  oslevel   '7100-09-03'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
