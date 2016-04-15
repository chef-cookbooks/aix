user 'foobar' do
  comment 'Alain Dejoux'
  uid 1234
  gid 'sys'
  home '/home/foobar'
  shell '/usr/bin/ksh'
  password 'zbpkcVZ.1okhk'
  supports manage_home: true
end

aix_inittab 'my-awesome-aix-daemon' do
  runlevel '2'
  processaction 'once'
  command '/opt/mycompany/libexec/mydaemon -d > /dev/console 2>&1'
  action :install
end

aix_subserver 'tftp' do
  protocol 'udp'
  action :disable
end

aix_tcpservice 'xntpd' do
  action :enable
end

aix_chsec '/etc/security/login.cfg' do
  attributes(maxlogins: 16_000, maxroles: 7, shells: '/bin/sh,/usr/bin/ksh')
  stanza 'usw'
  action :update
end

aix_etchosts 'test' do
  ip_address '1.1.1.1'
  action :add
end

aix_etchosts 'test' do
  ip_address '2.2.2.2'
  action :change
end

aix_etchosts 'test' do
  new_hostname 'test2'
  action :change
end

aix_etchosts 'test' do
  ip_address '1.1.1.1'
  aliases %w(test2 test3)
  action :add
end

aix_etchosts 'test' do
  action :delete
end

aix_etchosts 'delete all entries' do
  action :delete_all
end
