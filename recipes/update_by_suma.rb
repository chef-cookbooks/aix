###########
# variables
###########

target_lvl_sp='7100-03-04'
target_lvl_tl='7100-04'
target_lvl_latest='latest'
package_dir='/nim/inst.images'
client_list='quimby*'

#
# Initial conditions
# ------------------
# quimby07 => 7100-01-04-1216
# quimby08 => 7100-03-01-1341
# quimby09 => 7100-03-04-1441 (ref)
# quimby10 => 7100-03-05-1524
# quimby11 => 7100-04-00-0000
# quimby12 => 7200-00-02-1614
#

ohai 'reload_nim' do
  action :nothing
  plugin 'nim'
end

#################
# SUMA
# Download specific or latest installation images.
# And define NIM lpp_source object.
#################

aix_suma "Downloading SP image" do
	oslevel		"#{target_lvl_sp}"		# Name of the oslevel to download (if empty, assume latest)
	location	"#{package_dir}"		# Directory where the lpp will be stored and (if empty, assume /usr/sys/inst.images). If the directory does not exist, it will be created.
	targets		"#{client_list}"		# Mandatory list of standalone or master NIM 'machines' resources
	action 		:download
	#notifies	:reload, 'ohai[reload_nim]', :immediately
end

aix_suma "Downloading TL image" do
	oslevel		"#{target_lvl_tl}"		# Name of the oslevel to download (if empty, assume latest)
	location	"#{package_dir}"		# Directory where the lpp will be stored and (if empty, assume /usr/sys/inst.images). If the directory does not exist, it will be created.
	targets		"#{client_list}"		# Mandatory list of standalone or master NIM 'machines' resources
	action 		:download
	#notifies	:reload, 'ohai[reload_nim]', :immediately
end

aix_suma "Downloading LATEST image" do
	oslevel		"#{target_lvl_latest}"	# Name of the oslevel to download (if empty, assume latest)
	location	"#{package_dir}"		# Directory where the lpp will be stored and (if empty, assume /usr/sys/inst.images). If the directory does not exist, it will be created.
	targets		"#{client_list}"		# Mandatory list of standalone or master NIM 'machines' resources
	action 		:download
	#notifies	:reload, 'ohai[reload_nim]', :immediately
end

#################
# NIM
# Perfom nim cust operation on each targets based on their oslevel.
#################

#aix_nim "Updating machines" do
#	lpp_source	"#{target_lvl_tl}-lpp_source"
#	targets		"#{client_list}"
#	action		:update
#end
