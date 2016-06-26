actions :update
default_action :update
attr_accessor :exists

attribute :name, name_attribute: true, kind_of: String
attribute :attributes, kind_of: Hash
attribute :need_reboot, kind_of: [TrueClass, FalseClass], default: false
