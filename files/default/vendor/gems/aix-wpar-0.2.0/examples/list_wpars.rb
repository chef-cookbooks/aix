require 'wpars'
wpars = WPAR::WPARS.new(command: 'ssh adxlpar2')

wpars.generals.each do |entry|
  puts entry.inspect
end

# puts wpars['kitchenwpar'].networks.inspect
# puts wpars['kitchenwpar'].devices.inspect
# puts wpars['testwpar2'].get_rootvg.inspect

# start/stop examples
# wpars['testwpar2'].start
# wpars['testwpar2'].stop(force: true)
