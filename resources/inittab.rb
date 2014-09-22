actions :install, :remove

attribute :identifier, :name_attribute => true, :kind_of => String
attribute :runlevel, :kind_of => String, :required => true
attribute :processaction, :kind_of => String, :required => true, :equal_to => %w(respawn wait once boot bootwait powerfail off hold ondemand initdefault sysinit)
attribute :command, :kind_of => String, :required => true

attribute :follows, :kind_of => String

attr_accessor :exists

default_action :install
