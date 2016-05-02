actions :add, :change
default_action :add
attr_accessor :exists

attribute :name, :name_attribute => true, :kind_of => String

# Options for choosing disk(s)
attribute :disks, :kind_of => Array
attribute :best_fit, :kind_of => Fixnum, :default => 0
attribute :use_all_disks, :kind_of => [TrueClass, FalseClass], :default => false

# User defined options
attribute :options, :kind_of => Hash

# Options for mkvg command line execution
attribute :big, :kind_of => [TrueClass, FalseClass], :default => false
attribute :factor, :kind_of  => Fixnum
attribute :scalable, :kind_of => [TrueClass, FalseClass], :default => false
attribute :lv_number, :kind_of  => Fixnum
attribute :partitions, :kind_of => Fixnum, :equal_to => [32, 64, 128, 256, 512, 768, 1024, 2048]
attribute :powerha_concurrent, :kind_of => [TrueClass, FalseClass], :default => false
attribute :force, :kind_of => [TrueClass, FalseClass], :default => false
attribute :pre_53_compat, :kind_of => [TrueClass, FalseClass], :default => false
attribute :pv_type, :kind_of => String, :equal_to => ['none', 'SSD']
attribute :activate_on_boot, :kind_of => String, :equal_to => ['yes', 'no']
attribute :major_number, :kind_of => Fixnum
attribute :mirror_pool_strictness, :kind_of => String
attribute :mirror_pool, :kind_of => String, :equal_to => ['y','n','s']
attribute :infinite_retry, :kind_of => [TrueClass, FalseClass], :default => false
attribute :non_concurrent_varyon, :kind_of => String
attribute :critical_vg, :kind_of => [TrueClass, FalseClass], :default => false
attribute :partition_size, :kind_of => Fixnum

# Options for chvg which are not in common with mkvg
attribute :auto_synchronize, :kind_of => String, :equal_to => ['on', 'off']
attribute :hotspare, :kind_of => String, :equal_to => ['y','Y','n','r']
attribute :lost_quorom_varyoff, :kind_of => String, :equal_to => ['yes', 'no']
attribute :jfs2_resync_only, :kind_of => [TrueClass, FalseClass], :default => false
