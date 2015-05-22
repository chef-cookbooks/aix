
actions :create, :delete, :update
default_action :update

attribute :name, :kind_of => String, :name_attribute => true
attribute :uid, :kind_of => Integer
attribute :pgrp, :kind_of => String
attribute :groups, :kind_of => [Array, String]
attribute :home, :kind_of => String
attribute :shell, :kind_of => String
attribute :gecos, :kind_of => String
attribute :login, :kind_of => [TrueClass, FalseClass]
attribute :su, :kind_of => [TrueClass, FalseClass]
attribute :rlogin, :kind_of => [TrueClass, FalseClass]
attribute :daemon, :kind_of => [TrueClass, FalseClass]
attribute :admin, :kind_of => [TrueClass, FalseClass]
attribute :sugroups, :kind_of => String
attribute :admgroups, :kind_of => String
attribute :tpath, :kind_of => String
attribute :ttys, :kind_of => String
attribute :expires, :kind_of => Integer
attribute :auth1, :kind_of => String
attribute :auth2, :kind_of => String
attribute :umask, :kind_of => Integer
attribute :registry, :kind_of => String
attribute :SYSTEM, :kind_of => String
attribute :logintimes, :kind_of => String
attribute :loginretries, :kind_of => Integer
attribute :pwdwarntime, :kind_of => Integer
attribute :account_locked, :kind_of => [TrueClass, FalseClass]
attribute :minage, :kind_of => Integer
attribute :maxage, :kind_of => Integer
attribute :maxexpired, :kind_of => Integer
attribute :minalpha, :kind_of => Integer
attribute :minloweralpha, :kind_of => Integer
attribute :minupperalpha, :kind_of => Integer
attribute :minother, :kind_of => Integer
attribute :mindigit, :kind_of => Integer
attribute :minspecialchar, :kind_of => Integer
attribute :mindiff, :kind_of => Integer
attribute :maxrepeats, :kind_of => Integer
attribute :minlen, :kind_of => Integer
attribute :histexpire, :kind_of => Integer
attribute :histsize, :kind_of => Integer
attribute :pwdchecks, :kind_of => String
attribute :dictionlist, :kind_of => String
attribute :default_roles, :kind_of => String
attribute :fsize, :kind_of => Integer
attribute :cpu, :kind_of => Integer
attribute :data, :kind_of => Integer
attribute :stack, :kind_of => Integer
attribute :core, :kind_of => Integer
attribute :rss, :kind_of => Integer
attribute :nofiles, :kind_of => Integer
attribute :roles, :kind_of => String
attribute :crypt, :kind_of => String



attr_accessor :enabled, :exists


# TODO:
# *
# *


