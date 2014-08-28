actions :install, :remove

attribute :package_name, :name_attribute => true, :kind_of => String
attribute :base_url, :kind_of => String, :default => 'ftp://ftp.software.ibm.com/aix/freeSoftware/aixtoolbox/RPMS/ppc'

default_action :install
