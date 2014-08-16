# IBM AIX Toolbox for Linux Cookbook

## Supported Platforms

* AIX 6.1
* AIX 7.1

## Usage

This cookbook has no recipes. To install packages from the IBM AIX Toolbox for Linux, use the LWRPs in this cookbook like so:

```ruby
aixtoolbox_package "a2ps" do
  action :install
end
```

## License and Authors

* Author:: Julian C. Dunn (<jdunn@getchef.com>)
* Copyright:: (C) 2014 Chef Software, Inc.
* License:: Apache 2.0
