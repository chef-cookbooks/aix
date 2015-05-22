
actions :update
default_action :update

attribute :name, :kind_of => String, :name_attribute => true
attribute :attributes, :kind_of => Hash
attribute :atreboot, :kind_of => [TrueClass, FalseClass], :default => true

attr_accessor :exists


# TODO:
# *
# *

