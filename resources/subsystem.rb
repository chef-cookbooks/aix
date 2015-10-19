#
# Cookbook: aix
# License: Apache 2.0
#
# Copyright 2008-2015, Chef Software, Inc.
# Copyright 2015, Bloomberg Finance L.P.
#

actions :create, :delete
default_action :create

attribute :subsystem_name, name_attribute: true, kind_of: String
attribute :subsystem_synonym, kind_of: String
attribute :subsystem_group, kind_of: String
attribute :program, kind_of: String, required: true
attribute :arguments, kind_of: [String, Array]
attribute :standard_output, kind_of: String
attribute :standard_input, kind_of: String
attribute :standard_error, kind_of: String
attribute :user, kind_of: String, default: 'root'
attribute :use_signals, kind_of: [TrueClass, FalseClass], default: true
# default force_stop_signal is SIGKILL
attribute :force_stop_signal, kind_of: Fixnum, default: 9, equal_to: (1..34).to_a
# default normal_stop_signal is SIGTERM
attribute :normal_stop_signal, kind_of: Fixnum, default: 15, equal_to: (1..34).to_a
attribute :wait_time, kind_of: Fixnum

attr_accessor :exists
