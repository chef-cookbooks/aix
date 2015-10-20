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
attribute :arguments, kind_of: String
attribute :program, kind_of: String, required: true
attribute :user, kind_of: String, default: 'root'
attribute :standard_output, kind_of: String
attribute :standard_input, kind_of: String
attribute :standard_error, kind_of: String
attribute :auto_restart, kind_of: [TrueClass, FalseClass], default: false
attribute :multiple_instances, kind_of: [TrueClass, FalseClass], default: false
attribute :use_signals, kind_of: [TrueClass, FalseClass], default: true
attribute :use_sockets, kind_of: [TrueClass, FalseClass], default: false
attribute :use_message_queues, kind_of: [TrueClass, FalseClass], default: false
attribute :message_queue_key, kind_of: String
attribute :message_type, kind_of: String
attribute :priority, kind_of: Fixnum
# default normal_stop_signal is SIGTERM
attribute :normal_stop_signal, kind_of: Fixnum, default: 15, equal_to: (1..34).to_a
# default force_stop_signal is SIGKILL
attribute :force_stop_signal, kind_of: Fixnum, default: 9, equal_to: (1..34).to_a
attribute :show_inactive, kind_of: [TrueClass, FalseClass], default: true
attribute :wait_time, kind_of: Fixnum
attribute :subsystem_group, kind_of: String

attr_accessor :exists
