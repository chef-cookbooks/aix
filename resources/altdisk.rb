actions :create, :cleanup, :rename, :wakeup, :sleep, :customize
default_action :create
attr_accessor :exists

# value can be an hdisk* name, or a given size
# if you are searching for disk to perform an alternate disk copy
# type are:
#  - size : find a free disk with a size bigger or equal to value
#  - name : find a free disk with the same name as value
#  - auto : find the first free disk with a size bigger or equal to the current rootvg size
attribute :value, kind_of: String
attribute :type, kind_of: Symbol, equal_to: [:size, :name, :auto]
attribute :altdisk_name, kind_of: String
attribute :new_altdisk_name, kind_of: String
attribute :change_bootlist, kind_of: [TrueClass, FalseClass], default: false
attribute :image_location, kind_of: String
