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
