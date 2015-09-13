actions :update, :invalidate
default_action :update
attr_accessor :exists

attribute :name, :name_attribute => true, :kind_of => String
attribute :mode, :kind_of => Symbol, :equal_to => [:both,:normal,:service], :required => true
attribute :devices, :kind_of => Array
attribute :device_options, :kind_of => Hash
