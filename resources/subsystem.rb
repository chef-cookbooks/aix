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

attr_accessor :enabled
