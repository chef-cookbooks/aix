# recipe example update with suma

aix_suma 'dowload lastest patch' do
  dl_target = "/usr/sys/inst.images"
  filter_ml = "6100-05"
  action :download
end

aix_nim 'update set of clients' do
  location = "/usr/sys/inst.images"
  target = "client1,client2,client3"
  server = "master"
  action :update
end

