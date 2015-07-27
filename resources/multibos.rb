actions :create, :remove, :update, :mount, :umount
default_action :create
attr_accessor :exists

attribute :name, :kind_of => String, :name_attribute => true
attribute :update_device, :kind_of => String
attribute :bootlist, :kind_of => [TrueClass, FalseClass], :default => false
