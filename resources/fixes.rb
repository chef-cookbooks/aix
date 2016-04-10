actions :install, :remove
default_action :install
attr_accessor :exists

attribute :name, name_attribute: true, kind_of: String
attribute :fixes, kind_of: Array
attribute :directory, kind_of: String
