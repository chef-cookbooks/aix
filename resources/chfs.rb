
actions :update, :resize
default_action :resize

attribute :name, :kind_of => String, :name_attribute => true
attribute :size, :kind_of => Integer
attribute :unit, :kind_of => String, :equal_to => ["G", "M", "K"], :default => "G"
attribute :sign, :kind_of => String, :equal_to => ["+", "-", ""]
attribute :mountpoint, :kind_of => String
attribute :options, :kind_of => [String, Array]
attribute :automount, :kind_of => [TrueClass, FalseClass]

attr_accessor :exists


# TODO:
# *
# *

