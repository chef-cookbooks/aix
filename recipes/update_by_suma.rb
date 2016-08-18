###########
# variables
###########

target_dir='/var/inst.images'
lpp_source='6100_09_01_lppsrc'

#################
# SUMA
#################

aix_suma "Downloading SP 6100-09-01" do
	rq_type		'SP'
	rq_name		'6100-09-01'
	dl_target	"#{target_dir}"
	filter_ml	'6100-09'
	action 		:download
end

#################
# NIM
#################

aix_nim "Defining lpp_source" do
	type		'lpp_source'
	lpp_source	"#{lpp_source}"
	location	"#{target_dir}/installp/ppc"
	action		:define
end

aix_nim "Updating machines" do
	lpp_source	"#{lpp_source}"
	targets		'master'
	action		:cust
end

aix_nim "Removing lpp_source" do
	type		'lpp_source'
	lpp_source	"#{lpp_source}"
	action		:remove
end
