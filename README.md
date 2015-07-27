# AIX Cookbook

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

Change any AIX device attribute.Example:

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

Parameters:

* `need_reboot` (optional) - Add -P to the chdev command if device is busy

### no

Change any AIX no tunables. Example:

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

Parameters:

* `set_default` (optional) (default true) - All change are persistant to reboot (/etc/tunables/nextboot)
* `bootlist` (optional) (default false) - If set to true, the bootlist is not changed

Actions:

*  update - update a list of tunables
*  reset - reset a list of tunabes
*  reset_all - reset all tunables to default
*  reset_all_with_reboot - reset all tunables to default even if the ones that need a reboot

### multibos

Create,remove or update multibos on AIX. Example:

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

Parameters:

*  update_device (optional) - mount point used for update

Actions:

* create: create (and update if needed) a bos instance
* remove: remove a standby bos
* update: update all already create bos
* mount: mount a standby bos
* umount: umount a standby bos

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
