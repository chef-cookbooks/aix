name             'aix'
maintainer       'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license          'Apache-2.0'
description      'Custom resources useful for AIX systems'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.3.0'
source_url       'https://github.com/chef-cookbooks/aix'
issues_url       'https://github.com/chef-cookbooks/aix/issues'

supports 'aix', '>= 6.1'

chef_version '>= 12.7'
