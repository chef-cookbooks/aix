# AIX Cookbook

[![Build Status](https://travis-ci.org/chef-cookbooks/aix.svg?branch=master)](https://travis-ci.org/chef-cookbooks/aix)
[![Cookbook Version](https://img.shields.io/cookbook/v/aix.svg)](https://supermarket.chef.io/cookbooks/aix)

This cookbook contains useful resources for using Chef with AIX systems.

## Supported Platforms

* AIX 6.1
* AIX 7.1

## Usage

This cookbook has no recipes.

## Resources

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

### chdev

Change any AIX device attribute. Example:

```ruby
aix_chdev "sys0" do
  attributes(:maxuproc => 1026, ncargs: => 1024)
  need_reboot false
  action :update
end

aix_chdev "fcs0" do
  attributes(:num_cmd_elems => 200, :max_xfer_size => "0x800000")
  need_reboot true
  action :update
end

aix_chdev "ent0" do
  attributes(:poll_uplin => "yes")
  need_reboot true
  action :update
end
```

Parameters:

* `need_reboot` (optional) - Add -P to the chdev command if device is busy


### no

Change any AIX no (network) tunables. Example:

```ruby
aix_no "changing no tunables" do
  tunables(:udp_recv_perf => 0, :udprecvspace => 42083, :psetimers => 23)
  set_default
  action :update
end

aix_no "reseting no tunables" do
  tunables(:udp_recv_perf => 0, :udprecvspace => 0)
  set_default false
  action :reset
end

aix_no "reseting all no tunables" do
  action: reset_all
end

aix_no "reseting all no tunables reboot needed" do
  action: reset_all_with_reboot
end
```

Parameters:

* `set_default` (optional) (default true) - All change are persistant to reboot (/etc/tunables/nextboot)
* `bootlist` (optional) (default false) - If set to true, the bootlist is not changed

Actions:

* `update` - update a list of tunables
* `reset` - reset a list of tunabes
* `reset_all` - reset all tunables to default
* `reset_all_with_reboot` - reset all tunables to default even if the ones that need a reboot

### tunables

Change any AIX unrestricted tunables(vmo, ioo, schedo). Example:

```ruby
aix_tunables "reset schedo values" do
  mode :schedo
  action :reset_all
  permanent
end

aix_tunables "change vpm_throughput_mode" do
  mode :schedo
  tunables(:vpm_throughput_mode => 2)
  permanent
end

aix_tunables "change posix AIO servers" do
  mode :ioo
  tunables(posix_aio_minservers: 6, posix_aio_maxservers: 36)
end

aix_tunables "tune minperm%" do
  mode :vmo
  tunables( :"minperm%" => 6)
  permanent
end

aix_tunables "tune tcp buffers" do
  mode :vmo
  tunables( :udp_recvspace => 655360, :udp_sendspace => 65536 )
  permanent
end
```

Parameters:

* `mode` (mandatory) (no default) - must be :ioo, :vmo or :schedo
* `permament` (optional) (default false) - All changes are persistent
* `nextboot` (optional) (default false) - All changes applied on next boot only

Actions:

* `update` - update a list of tunables
* `reset` - reset a list of tunabes
* `reset_all` - reset all tunables to default

### multibos

Create, remove or update multibos on AIX. Example:

```ruby
aix_multibos "create a multibos no bootlist" do
  action :create
  bootlist true
end

aix_multibos "create and update a multibos" do
  action :create
  update_device "/mnt/7100-03-05-1524"
end

aix_multibos "remove standby multibos" do
  action :remove
end

aix_multibos "update a multibos" do
  action :update
  update_device "/mnt/7100-03-05-1524"
end

aix_multibos "mount a bos" do
  action :mount
end

aix_multibos "mount a bos" do
  action :umount
end
```

Parameters:

*  `update_device` (optional) - mount point used for update

Actions:

* `create` - create (and update if needed) a bos instance
* `remove` - remove a standby bos
* `update` - update all already create bos
* `mount` - mount a standby bos
* `umount` - umount a standby bos

### chsec
Changes the attributes in the security stanza files.

```ruby
aix_chsec "/etc/security/login.cfg" do
  attributes(:maxlogins => 16000, :maxroles => 7, :shells => "/bin/sh,/usr/bin/ksh")
  stanza "usw"
  action :update
end
```

Parameters:

* `file_name` (name_attribute) - security file to change
* `attribute` - array of attribut to change
* `stanza` - stanza to change

### etchosts

Add, change or remove entries in the /etc/hosts file.

```ruby
aix_etchosts "test" do
  ip_address "1.1.1.1"
  action :add
end

aix_etchosts "test" do
  ip_address "2.2.2.2"
  action :change
end

aix_etchosts "test" do
  new_hostname "test2"
  action :change
end

aix_etchosts "test" do
  ip_address "1.1.1.1"
  aliases ["test2", "test3"]
  action :add
end

aix_etchosts "test" do
  action :delete
end

aix_etchosts "delete all entries" do
  action :delete_all
end
```

Parameters:

* `name` - name of the host to change/add/delete
* `ip_address` - ip address
* `new_hostname` - new_hostame (use with change action)
* `aliases` - aliases

Actions:
* `add`  - add an entry in /etc/hosts
* `delete` - remove an entry in /etc/hosts
* `delete_all` - remove all entries in /etc/hosts
* `change` - change an entry in /etc/hosts

### niminit

Use niminit to configure the nimclient package.
This will look if /etc/niminfo exists and create it if it does not exist.
You can the use nimclient provider after niminiting the client.

```ruby
aix_niminit node[:hostname] do
  master "nimmaster"
  connect "nimsh"
  pif_name node[:network][:default_interface]
  action :setup
end

aix_niminit node[:hostname] do
  action :remove
end

aix_niminit node[:hostname] do
  master "nimmaster"
  connect "nimsh"
  pif_name "en1"
  action :setup
end
```
Parameters:

* `name` - hostname of the nimclient
* `master` - hostname of the nim master
* `pif_name` - interface name
* `connect` - nimsh or shell

Actions:
* `setup` - setup the nimclient
* `remove` - remove nimclient configuration

### nimclient

Use nimclient to install packages, update service pack, or technology level.
Your NIM server should meet these requirements to work with the nimclient provider:
* All resources name must end with the type of the resource (check example below):
 * 7100-03-05-1514-lpp_source
 * 7100-03-05-1514-spot
 * myinstallpbundle-installp_bundle
* All spot and lpp_source must match the exact oslevel output. To find the next available lpp_source or spot the provider is checking for your oslevel and comparing it with the lpp_source name
 * 7100-03-01-1341-lpp_source
 * 7100-03-02-1412-lpp_source
 * 7100-03-03-1415-lpp_source
 * 7100-03-04-1441-lpp_source
 * 7100-03-05-1524-lpp_source
 * 7100-03-01-1341-spot
 * 7100-03-02-1412-spot
 * 7100-03-03-1415-spot
 * 7100-03-04-1441-spot
 * 7100-03-05-1524-spot

Recommendation: create all the lpp_source with the simage attribute to avoid ambiguity.

```
$ lsnim -l 7100-03-05-1524-lpp_source
7100-03-05-1524-lpp_source:
   class       = resources
   type        = lpp_source
   arch        = power
   Rstate      = ready for use
   prev_state  = unavailable for use
   location    = /export/nim/lpp_source/7100-03-05-1524
   simages     = yes
   alloc_count = 1
   server      = master
```

Here are a few examples of recipes using nimclient:

```ruby
aix_nimclient "updating to latest available sp" do
  installp_flags "aXYg"
  lpp_source "latest_sp"
  fixes "update_all"
  action :cust
end

aix_nimclient "installing filesets from the latest available tl" do
  installp_flags "aXYg"
  lpp_source "latest_tl"
  filesets ["openssh.base.client","openssh.base.server","openssh.license"]
  action :cust
end

aix_nimclient "installing filesets from the next sp" do
  installp_flags "aXYg"
  lpp_source "next_sp"
  filesets ["security.pkcs11.tools"]
  action :cust
end

aix_nimclient "installing filesets" do
  installp_flags "aXYg"
  lpp_source "latest_sp"
  filesets ["Java6_64.samples"]
  action :cust
end

aix_nimclient "reset" do
  action :reset
end

aix_nimclient "deallocate" do
  action :deallocate
end

aix_nimclient "set date to nimmaster value" do
  action :set_date
end

aix_nimclient "disable push operations" do
  action :disable_push
end

aix_nimclient "enable push operations" do
  action :enable_push
end

aix_nimclient "maintbooting client" do
  spot "7100-03-01-1341-spot"
  action :maint_boot
end

aix_nimclient "bos_inst client" do
  spot "7100-03-01-1341-spot"
  lpp_source "7100-03-01-1341-lpp_source"
  action :bos_inst
end

aix_nimclient "allocating resources" do
  installp_bundle "toolbox-installp_bundle"
  lpp_source "7100-03-01-1341-lpp_source"
  spot "7100-03-01-1341-spot"
  action :allocate
end
```

Parameters:

* `spot` (optional) - name of the spot
* `lpp_source` (optional) - name of the lpp_source
* `installp_bundle` (optional) - name of the installp_bundle
* `filesets` - list of filesets to install
* `fixes` - fixe to install
* `installp_flags` - flags used for installp

Actions:

* `allocate` - create (and update if needed) a bos instance
* `deallocate` - remove a standby bos
* `cust` - update all already create bos
* `enable_push` - allow push operation from client
* `disable_push` -  disable push operation from client
* `set_date` - set date to that of the nim master
* `enable_crypto` - enable secure nimsh
* `disable_crypto` - disable secure nimsh
* `reset` - reset the client
* `bos_inst` - enable bos_install installation (you need to reboot the virtual machine after that)
* `maint_boot` - ennable maintenance boot (you need to reboot the virtual machine after that)

## License and Authors

* Author:: Julian C. Dunn (<jdunn@getchef.com>)
* Author:: Christoph Hartmann (<chris@lollyrock.com>)
* Author:: Benoit Creau (<benoit.creau@chmod666.org>)
* Author:: Alain Dejoux (<adejoux@djouxtech.net>)

```text
Copyright:: 2014-2015 Chef Software, Inc.

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
