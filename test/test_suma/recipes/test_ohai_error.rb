# Expected values
# return code : 1
# exception : OhaiNimPluginNotFound
# suma directory :
# suma metadata :
# suma preview :
# suma download :
# nim define :

node.default['nim'] = {}

aix_suma 'OHAI not found (Error)' do
  oslevel   '7100-02-02'
  location  '/sumatest/ohai/error'
  targets   'client1'
  action    :download
end
