###########
# variables
###########

target_lvl_sp_1='7100-04-02'
target_lvl_sp_2='7100-04-02-1612'
target_lvl_tl_1='7100-04'
target_lvl_tl_2='7100-04-00'
target_lvl_tl_3='7100-04-00-1525'
target_lvl_wrong='xxxx'
package_dir='/nim/inst.images'
client_list='quimby07,quimby08,quimby09,quimby10,quimby11,quimby12'

#
# Initial conditions
# ------------------
# quimby07 => 7200-00-01
# quimby08 => 7200-00-01
# quimby09 => 7100-03-04
# quimby10 => 7100-03-04
# quimby11 => 7200-00-02
# quimby12 => 7200-00-02
#

ohai 'reload_nim' do
  action :nothing
  plugin 'nim'
end

#################
# SUMA
# Download specific or latest installation images.
# And define NIM lpp_source object
#################

aix_suma "Downloading SP installation images (1)" do
	oslevel		"#{target_lvl_sp_1}"	# Name of the oslevel to download (if empty, assume latest)
	location	"#{package_dir}"		# Directory where the lpp will be stored and (if empty, assume /usr/sys/inst.images). If the directory does not exist, it will be created.
	targets		"#{client_list}"		# Mandatory list of standalone or master NIM 'machines' resources
	action 		:download
	notifies	:reload, 'ohai[reload_nim]', :immediately
end

# aix_suma "Downloading SP installation images (2)" do
	# oslevel		"#{target_lvl_sp_2}"	# Name of the oslevel to download (if empty, assume latest)
	# location	"#{package_dir}"		# Directory where the lpp will be stored and (if empty, assume /usr/sys/inst.images). If the directory does not exist, it will be created.
	# targets		"#{client_list}"		# Mandatory list of standalone or master NIM 'machines' resources
	# action 		:download
# end

# aix_suma "Downloading TL installation images (1)" do
	# oslevel		"#{target_lvl_tl_1}"	# Name of the oslevel to download (if empty, assume latest)
	# location	"#{package_dir}"		# Directory where the lpp will be stored and (if empty, assume /usr/sys/inst.images). If the directory does not exist, it will be created.
	# targets		"#{client_list}"		# Mandatory list of standalone or master NIM 'machines' resources
	# action 		:download
# end

# aix_suma "Downloading TL installation images (2)" do
	# oslevel		"#{target_lvl_tl_2}"	# Name of the oslevel to download (if empty, assume latest)
	# location	"#{package_dir}"		# Directory where the lpp will be stored and (if empty, assume /usr/sys/inst.images). If the directory does not exist, it will be created.
	# targets		"#{client_list}"		# Mandatory list of standalone or master NIM 'machines' resources
	# action 		:download
# end

# aix_suma "Downloading TL installation images (3)" do
	# oslevel		"#{target_lvl_tl_3}"	# Name of the oslevel to download (if empty, assume latest)
	# location	"#{package_dir}"		# Directory where the lpp will be stored and (if empty, assume /usr/sys/inst.images). If the directory does not exist, it will be created.
	# targets		"#{client_list}"		# Mandatory list of standalone or master NIM 'machines' resources
	# action 		:download
# end

# aix_suma "Downloading latest installation images" do
	# location	"#{package_dir}"		# Directory where the lpp will be stored and (if empty, assume /usr/sys/inst.images). If the directory does not exist, it will be created.
	# targets		"#{client_list}"		# Mandatory list of standalone or master NIM 'machines' resources
	# action 		:download
# end

#aix_suma "Downloading installation images ERROR" do
#	oslevel		"#{target_lvl_wrong}"	# Name of the oslevel to download (if empty, assume latest)
#	location	"#{package_dir}"		# Directory where the lpp will be stored and (if empty, assume /usr/sys/inst.images). If the directory does not exist, it will be created.
#	targets		"#{client_list}"		# Mandatory list of standalone or master NIM 'machines' resources
#	action 		:download
#end

#
# What suma will do ?
# -------------------
# Populate this directory and create according nim resource ...
#	/nim/inst.images/7100-09-04-lpp_source/installp/ppc/
# ... with following commands:
#   suma -x -a RqType=SP -a RqName=7100-09-04 -a FilterML=7100-07 -a DLTarget=/nim/inst.images/7100-09-04-lpp_source
#   nim -o define -t lpp_source -a server=master -a location=/nim/inst.images/7100-09-04-lpp_source 7100-09-04-lpp_source
#

#################
# NIM
# Perfom nim cust operation on each targets based on their oslevel.
#################

#aix_nim "Updating machines" do
#	lpp_source	"#{target_lvl_sp_1}-lpp_source"
#	targets		"#{client_list}"
#	action		:update
#end

#
# What nim will do ?
# ------------------
# Install NIM lpp_source on quimby09 and quimby11 with following command:
#   nim -o cust -a lpp_source=7100-09-04-lpp_source quimby09,quimby11
#
