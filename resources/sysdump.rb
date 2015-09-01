actions :change
default_action :change
attr_accessor :exists

attribute :permanent, :kind_of => [TrueClass, FalseClass], :default => true
attribute :primary_device, :kind_of => String
attribute :secondary_device, :kind_of => String
