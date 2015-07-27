actions :update, :reset, :reset_all, :reset_all_with_reboot
default_action :update
attr_accessor :exists

attribute :name, :name_attribute => true, :kind_of => String
attribute :tunables, :kind_of => Hash
attribute :set_default, :kind_of => [TrueClass, FalseClass], :default => false
