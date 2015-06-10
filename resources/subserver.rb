actions :enable, :disable

attribute :servicename, :name_attribute => true, :kind_of => String
attribute :type, :kind_of => String, :equal_to => %w(dgram stream sunrpc_udp sunrpc_tcp)
attribute :protocol, :kind_of => String, :required => true, :equal_to => %w(tcp udp tcp6 udp6)
attribute :wait, :kind_of => String, :default => 'nowait', :equal_to => %w(wait nowait SRC)
attribute :user, :kind_of => String, :default => 'root', :required => true
attribute :program, :kind_of => String
attribute :args, :kind_of => String

attr_accessor :enabled, :exists, :already_exists_with_new_name

default_action :enable
