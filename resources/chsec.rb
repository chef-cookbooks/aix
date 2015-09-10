actions :update
default_action :update
attr_accessor :exists

attribute :file_name, name_attribute: true, kind_of: String
attribute :attributes, kind_of: Hash
attribute :stanza, kind_of: String
