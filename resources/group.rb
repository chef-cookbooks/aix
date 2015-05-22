
actions :create, :delete, :update
default_action :update

attribute :name, :kind_of => String, :name_attribute => true
attribute :gid, :kind_of => Integer
attribute :admin, :kind_of => [TrueClass, FalseClass]
attribute :users, :kind_of => [Array, String]
attribute :adms, :kind_of => String
attribute :registry, :kind_of => String

attr_accessor :enabled, :exists


# TODO:
# *
# *


