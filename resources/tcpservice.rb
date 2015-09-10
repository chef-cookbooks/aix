actions :enable, :disable

attribute :identifier, name_attribute: true, kind_of: String
attribute :immediate, kind_of: [TrueClass, FalseClass], default: false

attr_accessor :enabled

default_action :enable
