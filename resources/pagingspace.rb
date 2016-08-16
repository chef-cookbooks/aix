actions :change, :remove, :create
default_action :change
attr_accessor :exists

# example of lsps -ca
# name:Pvname:Vgname:Size:Used:Active:Auto:Type:Chksum
# hd6:hdisk0:rootvg:8:1:y:n:lv:0

attribute :name, name_attribute: true, kind_of: String
attribute :vgname, kind_of: String
attribute :pvname, kind_of: String
attribute :size, kind_of: Fixnum
attribute :active, kind_of: [TrueClass, FalseClass], default: true
attribute :auto, kind_of: [TrueClass, FalseClass], default: true
