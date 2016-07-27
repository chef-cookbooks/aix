# recipe example update with suma

aix_suma 'configure suma' do
  dl_timeout_sec=360
  remove_conflictiong_updates=true
  tmpdir='/var/suma/tmp'
  action :config
end

aix_suma 'run download' do
  suma_action='Clean'
  action :run
end

aix_suma 'Clean all suma task list' do
  action :deleteall
end

aix_suma 'Add task in schedule' do
  suma_action='Download'
  cron_sched="00 00 * * *"
  rq_type="Latest"
  notify_email="laurent.gay@atos.net"
  dl_target="/usr/sys/inst.images"
  action :schedule
end

