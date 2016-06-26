actions :update
default_action :update
attr_accessor :exists

attribute :name, name_attribute: true, kind_of: String
attribute :attributes, kind_of: Hash
# need_reboot and hot_change cannot be used at the same time
attribute :need_reboot, kind_of: [TrueClass, FalseClass], default: false
attribute :hot_change, kind_of: [TrueClass, FalseClass], default: false
