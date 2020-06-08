require 'wpars'

#new wpar named testwpar
wpar = WPAR::WPAR.new(command: "ssh adxlpar2", name: "testwpar2")

#live stream output
wpar.live_stream=STDOUT

#set hostname if different
wpar.general.hostname="testwpar2"

#set auto start
wpar.general.auto="yes"

#create wpar
wpar.create

#stop wpar
wpar.stop(force: true)

#start wpar
wpar.start

#sync wpar
wpar.sync

#delete
wpar.destroy(force: true)
