# :allocate - allocate a resource
# :deallocate - deallocate a resource
# :cust - run a cust operation
# :enable_push - allow nimclient to do push operation
# :disable_push - disable push operation from the client
# :set_date - synchronize date and time with the nim master
# :enable_crypto - enable secure nimsh
# :disable_crypto - disable secure nimsh
# :reset - reset client state
# :bos_inst - peform bos_inst operation
# :maint_boot - peform maint_boot operation
actions :allocate, :deallocate, :cust, :enable_push, :disable_push, :set_date, :enable_crypto, :disable_crypto, :reset, :bos_inst, :maint_boot
# I think the most common action is cust
default_action :cust
attr_accessor :exists

# Generaly use the current oslevel to find the spot name
attribute :spot, :kind_of => String
# I assume here that your lppsource are named 7100-03-05-1524-lppsource, 6100-09-05-1524-lppsource (change this to fit you nim naming convention)
# if you want to put anything here you can just leave this to string
attribute :lpp_source, :kind_of => String, :regex => [/next_sp/, /latest_sp/, /next_tl/, /latest_tl/, /[7100,6100,5300]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]-lpp_source/, /.*-lpp_source/]
attribute :installp_bundle, :kind_of => String, :regex => [ /.*-installp_bundle/ ]
# Lists of filesets to install
attribute :filesets, :kind_of => Array
# fixes to install can be update_all for all
attribute :fixes, :kind_of => String
attribute :installp_flags, :kind_of =>String
