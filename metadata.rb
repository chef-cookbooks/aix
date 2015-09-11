name             'aix'
maintainer       'Chef Software, Inc.'
maintainer_email 'jdunn@chef.io'
license          'Apache 2.0'
description      'Custom resources useful for AIX systems'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
source_url       'https://github.com/chef-cookbooks/aix' if respond_to?(:source_url)
issues_url       'https://github.com/chef-cookbooks/aix/issues' if respond_to?(:issues_url)

supports 'aix', '>= 6.1'
