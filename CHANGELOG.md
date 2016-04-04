# aix Cookbook CHANGELOG

This file is used to list changes made in each version of the aix cookbook.

# 1.0.0 (2016-04-04)

- Added a new `tunable` custom resource. See the readme for usage details
- Added a new `bootlist` custom resource. See the readme for usage details
- Added a new `altdisk` custom resource. See the readme for usage details
- Added a new `subsystem` custom resource.
- Updated Travis CI to test using ChefDK
- Added a standard rubocop.yml and resolved issues
- Added the full Apache 2.0 license file
- Added testing and contributing docs
- Added a Gemfile with testing dependencies
- Added a long_description to the metadata
- Added Chef 11 compatibility check to issues_url and source_url in the metadata

# 0.1.0

- Added significantly more resources to the cookbook (@chmod666)

# 0.0.2

- Remove deprecated #each from providers; replace with #each_line
- Upgrade some packages, particularly bash to remediate shellshock
- Fix missing include in provider

# 0.0.1

Initial release
