actions :create, :start, :stop, :delete
default_action :create
attr_accessor :exists

attribute :name, name_attribute: true, kind_of: String
attribute :hostname, kind_of: String
attribute :address, kind_of: String
attribute :interface, kind_of: String
attribute :rootvg, kind_of: [TrueClass, FalseClass], default: false
attribute :rootvg_disk, kind_of: String
attribute :datavg, kind_of: String
attribute :backupimage, kind_of: String
attribute :cpu, kind_of: String
attribute :memory, kind_of: String
attribute :autostart, kind_of: [TrueClass, FalseClass], default: false
attribute :state,kind_of: String, default: nil
