# recipe example scheduling suma tasks
# This recipe is interactive and allows upgrade of AIX 7.1 and 7.2 machines

Chef::Recipe.send(:include, AIX::PatchMgmt)

nodes = Hash.new { |h, k| h[k] = {} }
nodes['machine'] = node['nim']['clients'].keys
nodes['oslevel'] = node['nim']['clients'].values.collect { |m| m.fetch('oslevel', nil) }
nodes['Cstate'] = node['nim']['clients'].values.collect { |m| m.fetch('lsnim', {}).fetch('Cstate', nil) }

puts '#########################################################'
puts 'Available machines and their corresponding oslevel are:'
puts print_hash_by_columns(nodes)
puts 'Choose one or more (comma-separated) to update ?'
client = STDIN.readline.chomp

levels = { '7.1 TL0' => ['7100-00-00-0000', '7100-00-01-1037', '7100-00-02-1041', '7100-00-03-1115', '7100-00-04-1140', '7100-00-05-1207', '7100-00-06-1216', '7100-00-07-1228', '7100-00-08-1241', '7100-00-09-1316', '7100-00-10-1334'],
           '7.1 TL1' => ['7100-01-00-0000', '7100-01-01-1141', '7100-01-02-1150', '7100-01-03-1207', '7100-01-04-1216', '7100-01-05-1228', '7100-01-06-1241', '7100-01-07-1316', '7100-01-08-1334', '7100-01-09-1341', '7100-01-10-1415'],
           '7.1 TL2' => ['7100-02-00-0000', '7100-02-01-1245', '7100-02-02-1316', '7100-02-03-1334', '7100-02-04-1341', '7100-02-05-1415', '7100-02-06-1441', '7100-02-07-1524'],
           '7.1 TL3' => ['7100-03-00-0000', '7100-03-01-1341', '7100-03-02-1412', '7100-03-03-1415', '7100-03-04-1441', '7100-03-05-1524', '7100-03-06-1543', '7100-03-07-1614'],
           '7.1 TL4' => ['7100-04-00-0000', '7100-04-01-1543', '7100-04-02-1614'],
           '7.2 TL0' => ['7200-00-00-0000', '7200-00-01-1543', '7200-00-02-1614'] }
levels.each do |k, v|
  levels[k] = v.collect do |oslevel|
    if node['nim']['lpp_sources'].keys.include?("#{oslevel}-lpp_source")
      oslevel + '*'
    else
      oslevel
    end
  end
end

puts '#########################################################'
puts 'Available SP/TL levels are:'
puts print_hash_by_columns(levels)
puts 'Choose one to download and install ?'
level = STDIN.readline.chomp

directory = '/export/extra/lpp_source'

aix_suma "List suma info" do
  action [:default, :list, :config]
end

aix_suma "Execute a preview task and do not save it" do
  oslevel level
  location directory
  targets client
  action :preview
end

aix_suma "Execute a preview task and save it" do
  oslevel level
  location directory
  targets client
  save_it true
  action :preview
end

=begin
NO SUPPORT FOR CREATION WITHOUT EXECUTION
aix_suma "Create a preview task and save it" do
  oslevel level
  location directory
  targets client
  save_it true
  action :preview
end
=end

aix_suma "Create a preview task and schedule it" do
  oslevel level
  location directory
  targets client
  sched_time '30 2 15 * *'
  action :preview
end

aix_suma "Edit an existing task" do
  task_id 2
  action :edit
  only_if "/usr/sbin/suma -l 2"
end

aix_suma "Edit and schedule an existing task" do
  sched_time '30 2 15 * *'
  task_id 2
  action :edit
  only_if "/usr/sbin/suma -l 2"
end

aix_suma "Unschedule an existing task" do
  sched_time ''
  task_id 2
  action :edit
  only_if "/usr/sbin/suma -l 2"
end

aix_suma "Unschedule an existing task" do
  task_id 2
  action :unschedule
  only_if "/usr/sbin/suma -l 2"
end

aix_suma "Delete an existing task" do
  task_id 2
  action :delete
  only_if "/usr/sbin/suma -l 2"
end
