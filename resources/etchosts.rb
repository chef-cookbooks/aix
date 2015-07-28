actions :add, :delete, :delete_all, :change
default_action :add
attr_accessor :exists

attribute :name, :name_attribute => true, :kind_of => String
attribute :ip_address, :kind_of => String
attribute :new_hostname, :kind_of => String
attribute :aliases, :kind_of => Array
