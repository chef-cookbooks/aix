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
attribute :factor, :kind_of  => Fixnum, :default => 0
attribute :scalable, :kind_of => [TrueClass, FalseClass], :default => false
attribute :lv_number, :kind_of  => Fixnum, :default => 0
attribute :partitions, :kind_of => Fixnum, :equal_to => [32, 64, 128, 256, 512, 768, 1024, 2048], :default => 0
attribute :powerha_concurrent, :kind_of => [TrueClass, FalseClass], :default => false
attribute :force, :kind_of => [TrueClass, FalseClass], :default => false
attribute :pre_53_compat, :kind_of => [TrueClass, FalseClass], :default => false
attribute :pv_type, :kind_of => String, :equal_to => ['none', 'SSD'], :default => ''
attribute :activate_on_boot, :kind_of => [TrueClass, FalseClass], :default => true
attribute :major_number, :kind_of => Fixnum, :default => 0
attribute :mirror_pool_strictness, :kind_of => String, :default => ''
attribute :mirror_pool, :kind_of => String, :equal_to => ['y','n','s'], :default => ''
attribute :infinite_retry, :kind_of => [TrueClass, FalseClass], :default => false
attribute :non_concurrent_varyon, :kind_of => String, :default => ''
attribute :critical_vg, :kind_of => [TrueClass, FalseClass], :default => false
attribute :partition_size, :kind_of => Fixnum, :default => 0

# Options for chvg which are not in common with mkvg
attribute :auto_synchronize, :kind_of => [TrueClass, FalseClass], :default => false
attribute :hotspare, :kind_of => String, :equal_to => ['y','Y','n','r'], :default => ''
attribute :make_non_concurrent, :kind_of => [TrueClass, FalseClass], :default => false
attribute :lost_quorom_varyoff, :kind_of => [TrueClass, FalseClass], :default => true
attribute :drain_io, :kind_of => [TrueClass, FalseClass], :default => false
attribute :resume_io, :kind_of => [TrueClass, FalseClass], :default => false
attribute :grow, :kind_of => [TrueClass, FalseClass], :default => false
attribute :bad_block_relocation, :kind_of => [TrueClass, FalseClass], :default => true
attribute :jfs2_resync_only, :kind_of => [TrueClass, FalseClass], :default => false
