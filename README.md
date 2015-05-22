# AIX Cookbook

This cookbook contains useful resources for using Chef with AIX systems.

## Supported Platforms

* AIX 6.1
* AIX 7.1

## Usage

This cookbook has no recipes.

## Resources

### user

```ruby
aix_user 'root' do
  action :update
  crypt "root's new crypt"
end
```
valid actions : 

* :create
* :update
* :delete

Parameters:

* `:name` :kind_of => String 
* `:uid` :kind_of => Integer 
* `:pgrp` :kind_of => String 
* `:groups` :kind_of => [Array, String] 
* `:home` :kind_of => String 
* `:shell` :kind_of => String 
* `:gecos` :kind_of => String 
* `:login` :kind_of => [TrueClass, FalseClass] 
* `:su` :kind_of => [TrueClass, FalseClass]
* `:rlogin` :kind_of => [TrueClass, FalseClass]
* `:daemon` :kind_of => [TrueClass, FalseClass]
* `:admin` :kind_of => [TrueClass, FalseClass]
* `:sugroups` :kind_of => String
* `:admgroups` :kind_of => String
* `:tpath` :kind_of => String
* `:ttys` :kind_of => String
* `:expires` :kind_of => Integer
* `:auth1` :kind_of => String
* `:auth2` :kind_of => String
* `:umask` :kind_of => Integer
* `:registry` :kind_of => String
* `:SYSTEM` :kind_of => String
* `:logintimes` :kind_of => String
* `:loginretries` :kind_of => Integer
* `:pwdwarntime` :kind_of => Integer
* `:account_locked` :kind_of => [TrueClass, FalseClass]
* `:minage` :kind_of => Integer
* `:maxage` :kind_of => Integer
* `:maxexpired` :kind_of => Integer
* `:minalpha` :kind_of => Integer
* `:minloweralpha` :kind_of => Integer
* `:minupperalpha` :kind_of => Integer
* `:minother` :kind_of => Integer
* `:mindigit` :kind_of => Integer
* `:minspecialchar` :kind_of => Integer
* `:mindiff` :kind_of => Integer
* `:maxrepeats` :kind_of => Integer
* `:minlen` :kind_of => Integer
* `:histexpire` :kind_of => Integer
* `:histsize` :kind_of => Integer
* `:pwdchecks` :kind_of => String
* `:dictionlist` :kind_of => String
* `:default_roles` :kind_of => String
* `:fsize` :kind_of => Integer
* `:cpu` :kind_of => Integer
* `:data` :kind_of => Integer
* `:stack` :kind_of => Integer
* `:core` :kind_of => Integer
* `:rss` :kind_of => Integer
* `:nofiles` :kind_of => Integer
* `:roles` :kind_of => String
* `:crypt` :kind_of => String

### group

```ruby
aix_group 'aixgroup1' do
  action :update
  gid 800
end
```
valid actions : 

* :create
* :update
* :delete

Parameters:

* `:name`:kind_of => String`:name_attribute `=> true
* `:gid`:kind_of => Integer
* `:admin`:kind_of => [TrueClass, FalseClass]
* `:users`:kind_of => [Array, String]
* `:adms`:kind_of => String
* `:registry`:kind_of => String

### chdev

```ruby
aix_chdev 'sys0' do
  action :update
  attributes(:maxuproc => 16384, :iostat => true )
  atreboot false
end
```
valid actions : 

* :update

Parameters:

* `:name` :kind_of => String, :name_attribute => true
* `:attributes` :kind_of => Hash
* `:atreboot` :kind_of => [TrueClass, FalseClass], :default => true

### chfs

```ruby
aix_chfs "/tmp" do
  action :resize
  size 4
  unit "G"
end
```
valid actions : 

* :rezie

Parameters:

* `:name` :kind_of => String, :name_attribute => true
* `:size` :kind_of => Integer
* `:unit` :kind_of => String, :equal_to => ["G", "M", "K"], :default => "G"
* `:sign` :kind_of => String, :equal_to => ["+", "-", ""]
* `:mountpoint` :kind_of => String / not yet implemented
* `:options` :kind_of => [String, Array] / not yet implemented
* `:automount` :kind_of => [TrueClass, FalseClass] / not yet implemented
 
### inittab

Manage the inittab entries. Example:

```ruby
aix_inittab 'my-awesome-aix-daemon' do
  runlevel '2'
  processaction 'once'
  command '/opt/mycompany/libexec/mydaemon -d > /dev/console 2>&1'
  action :install
end
```

Parameters:

* `runlevel` - the runlevel of the inittab entry
* `processaction` - the action of the process (e.g. "once", "boot", etc.)
* `command` - the command to run

### subserver

Manage the services started by `inetd` by editing `/etc/inetd.conf`. Example:

```ruby
aix_subserver 'tftp' do
  protocol 'udp'
  action :disable
end
```

Parameters:

* `servicename` - name of the service as it appears in the first field of `/etc/inetd.conf`
* `type` - type of service. Valid values: `dgram stream sunrpc_udp sunrpc_tcp`
* `protocol` - protocol of service. Valid values: `tcp udp tcp6 udp6`
* `wait` - blocking, nonblocking, or SRC. Valid values: `wait nowait SRC`
* `user` - user to the run the service under. Default: `root`
* `program` - program to run (typically specified by full path)
* `args` - program, with arguments

### tcpservice

Manage the services started by `/etc/rc.tcpip`. Example:

```ruby
aix_tcpservice 'xntpd' do
  action :enabled
end
```

Parameters:

* `immediate` (optional) - whether to start/stop the TCP/IP service
  immediately by contacting the SRC. It's much better to declaratively
  specify this separately using the built-in `service` resource in
  Chef.

### toolboxpackage

To install packages from the IBM AIX Toolbox for Linux off the IBM FTP
site. Example:

```ruby
aix_toolboxpackage "a2ps" do
  action :install
end
```

Parameters:

* `base_url` (optional) - the base URL to use to retrieve the package.
  If you are behind a firewall or your AIX system doesn't have access
  to the Internet, you can override this to an HTTP/FTP server where
  you have stored the RPMs.

## License and Authors

* Author:: Julian C. Dunn (<jdunn@getchef.com>)
* Author:: Christoph Hartmann (<chris@lollyrock.com>)

```text
Copyright:: 2014 Chef Software, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
