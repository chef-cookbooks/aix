def print_hash_by_columns (data)
  widths={}
  data.keys.each do |key|
    widths[key] = 5   # minimum column width
    # longest string len of values
    val_len = data[key].max_by{ |v| v.to_s.length }.to_s.length
    widths[key] = (val_len > widths[key]) ? val_len : widths[key]
    # length of key
    widths[key] = (key.to_s.length > widths[key]) ? key.to_s.length : widths[key]
  end
  
  result = "+"
  data.keys.each {|key| result += "".center(widths[key]+2, '-') + "+" }
  result += "\n"
  result += "|"
  data.keys.each {|key| result += key.to_s.center(widths[key]+2) + "|" }
  result += "\n"
  result += "+"
  data.keys.each {|key| result += "".center(widths[key]+2, '-') + "+" }
  result += "\n"
  length=data.values.max_by{ |v| v.length }.length
  for i in 0.upto(length-1)
    result += "|"
    data.keys.each { |key| result += data[key][i].to_s.center(widths[key]+2) + "|" }
    result += "\n"
  end
  result += "+"
  data.keys.each {|key| result += "".center(widths[key]+2, '-') + "+" }
  result += "\n"
  result
end

levels={ '7.1 TL0' => ['7100-00-00-0000', '7100-00-01-1037', '7100-00-02-1041', '7100-00-03-1115', '7100-00-04-1140', '7100-00-05-1207', '7100-00-06-1216', '7100-00-07-1228', '7100-00-08-1241', '7100-00-09-1316', '7100-00-10-1334'],
		 '7.1 TL1' => ['7100-01-00-0000', '7100-01-01-1141', '7100-01-02-1150', '7100-01-03-1207', '7100-01-04-1216', '7100-01-05-1228', '7100-01-06-1241', '7100-01-07-1316', '7100-01-08-1334', '7100-01-09-1341', '7100-01-10-1415'],
		 '7.1 TL2' => ['7100-02-00-0000', '7100-02-01-1245', '7100-02-02-1316', '7100-02-03-1334', '7100-02-04-1341', '7100-02-05-1415', '7100-02-06-1441', '7100-02-07-1524'],
		 '7.1 TL3' => ['7100-03-00-0000', '7100-03-01-1341', '7100-03-02-1412', '7100-03-03-1415', '7100-03-04-1441', '7100-03-05-1524', '7100-03-06-1543', '7100-03-07-1614'],
		 '7.1 TL4' => ['7100-04-00-0000', '7100-04-01-1543', '7100-04-02-1614'],
		 '7.2 TL0' => ['7200-00-00-0000', '7200-00-01-1543', '7200-00-02-1614'],
         'Latest' => [] }

#machines=Hash.new{ |h,k| h[k] = [ node['nim']['clients'][k]['oslevel'] ]}#, node['nim']['clients'][k]['Cstate'] ] }
#machines['machine']=['oslevel'] #,'Cstate']
#node['nim']['clients'].keys.sort.each { |key| machines[key] }
#puts machines
#nodes=Hash.new{ |h,k| h[k] = { 'machine' => k, 'oslevel' => node['nim']['clients'][k]['oslevel'] } }
#node['nim']['clients'].keys.sort.each { |key| nodes[key] }
#puts nodes
nodes=Hash.new{ |h,k| h[k] = {} }
nodes['machine']=node['nim']['clients'].keys
nodes['oslevel']=node['nim']['clients'].values.collect { |client| client['oslevel'] }
nodes['Cstate']=node['nim']['clients'].values.collect { |client| client['lsnim']['Cstate'] }

puts ""
puts "#########################################################"
puts "Available machines and their corresponding oslevel are:"
puts print_hash_by_columns(nodes)
puts "Choose one or more (comma-separated) to update ?"
client=STDIN.readline.chomp

puts ""
puts "#########################################################"
puts "Available SP/TL levels are:"
puts print_hash_by_columns(levels)
puts "Choose one or latest to download and install ?"
level=STDIN.readline.chomp

directory='/export/extra/lpp_source'

ohai 'reload_nim' do
  action :nothing
  plugin 'nim'
end

aix_suma "Downloading #{level} installation images" do
	oslevel		"#{level}"
	location	"#{directory}"
	targets		"#{client}"
	action 		:download
	notifies	:reload, 'ohai[reload_nim]', :immediately
end

aix_nim "Updating machine - 1st pass" do
	lpp_source	"#{level}-lpp_source"
	targets		"#{client}"
	async		false
	action		:update
end


=begin
aix_nim "Updating machine - 2nd pass" do
	lpp_source	"#{level}-lpp_source"
	targets		"#{client}"
	action		:update
end
=end
