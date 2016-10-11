aix_etchosts 'testwpar' do
  ip_address '9.128.136.201'
  action :add
end

aix_wpar 'create wpar' do
  action :create
  name 'testwpar'
  hostname 'testwpar'
  cpu '10%-50%,100%'
  live_stream true
  autostart true
end

aix_wpar 'stop wpar' do
 action :stop
 name 'testwpar'
 live_stream true
end

aix_wpar 'delete wpar' do
 action :delete
 name 'testwpar'
end
