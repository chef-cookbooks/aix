actions :setup, :remove
default_action :setup
attr_accessor :exists

attribute :name, name_attribute: true, kind_of: String
attribute :master, kind_of: String
attribute :pif_name, kind_of: String
attribute :connect, kind_of: String, equal_to: %w(shell nimsh), default: 'nimsh'
