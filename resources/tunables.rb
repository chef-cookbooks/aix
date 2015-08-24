actions :update, :reset, :reset_all
default_action :update
attr_accessor :exists

attribute :name, :name_attribute => true, :kind_of => String
attribute :mode, :kind_of => Symbol, :equal_to => [:ioo,:vmo,:schedo, :no], :required => true
attribute :tunables, :kind_of => Hash
attribute :permanent, :kind_of => [TrueClass, FalseClass], :default => false
attribute :nextboot, :kind_of => [TrueClass, FalseClass], :default => false
