actions :enable, :disable

attribute :servicename, :name_attribute => true, :kind_of => String
attribute :type, :kind_of => String, :values => %w(dgram stream sunrpc_udp sunrpc_tcp)
attribute :protocol, :kind_of => String, :required => true, :values => %w(tcp udp)
attribute :wait, :kind_of => String, :default => 'nowait', :values => %w(wait nowait SRC)
attribute :user, :kind_of => String, :default => 'root', :required => true
attribute :program, :kind_of => String
attribute :args, :kind_of => String

attr_accessor :enabled

default_action :enable

# TODO:
# * Validation method (if possible) to ensure that stream sockets are nowait only
# * Validation method (if possible) to ensure that if type is sunrpc_udp, that protocol is udp and same for tcp
