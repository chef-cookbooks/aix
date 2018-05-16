# aix Cookbook CHANGELOG

This file is used to list changes made in each version of the aix cookbook.

## 2.3.1 (2018-05-16)

- Don't .to_s strings
- Use the chef shell_out mixin vs. mixlib_shellout
- Properties that are Strings default to nil so we can remove the nil defaults
- Remove empty load_current_value method which isn't doing anything
- Load current resource properly instead of tracking state in properties
- Remove redundant default_action
- Use new_resource instead of @new_resource in several resources
- Fix strings in the examples to properly interpolate
- Fix error message to actually output the error
- Update the rubocop rules we disable
- Resolve FC019 warnings in the examples
- Disable FC0113 for now since we still support Chef 12
- Fix loading current_resource in the inittab resource

## 2.3.0 (2018-05-10)

- Resolve incompatibilities with Chef 13 & 14
- Removed Chefspec matchers which are autogenerted by ChefSpec now
- Added a new nimviosupdate resource
- Update etchosts resource to update aliases if they are changed
- Fixes to aix_chsec to use the name property of the resource and to better handle filesystem names

## 2.2.0 (2017-12-21)

- Convert nimclient and toolboxpackage to custom resources
- Add back the subsystem provider which was removed by accident

## 2.1.0 (2017-12-01)

- etchost resource converted to custom resource to support Chef 13. Thanks Mike Sgarbossa.
- documentation cleanup

## 2.0.1 (2017-11-08)

- Adds support for Chef 13 in the wpar resource by changing the state property to wpar_state
- Removing duplicate xpm package for library/helpers.rb, keeping aix6.1 version
- Removing extra line before rescue, to satisfy tests
- Fixing foodcritic error FC092 by removing 'actions' line

## 2.0.0 (2017-11-08)

- chdev, chsec, no, subserver, tcpservice, and tunables converted to custom resources. This increases the minimum required chef-client version to 12.7. Thanks Mike Sgarbossa
- Chef 13 compatibility fixes. Thanks Mike Sgarbossa
- Added new suma, nim and flrtvc resources. Thanks V. Robin
- Add Availability to download updates for a specific Service Pack without giving a list of NIM client machines. Thanks ponceta-jm
- inittab converted to a custom resource. Thanks lamont
- Fixed license string to be a SPDX standard license string
- Fixes and improved logging in the fixes resource
- Added a nim_master_setup recipe
- Added a nim_master_setup_standalone recipe

## 1.2.1 (2017-03-02)

- Fix missing attributes for aix_altdisk
- Update testing to use delivery local
- Cookstyle fixes

## 1.2.0 (2016-10-20)

- Fix failures if the wpars gem is missing and dynamically install it instead
- add suma resource
- add nim resource
- add lvm resource
- Moved testing / example cookbooks out of the recipes directory and into an examples directory
- Use the shell_out! helper to provide proper logging of output
- Testing improvements for foodcritic and Cookstyle
- Add ChefSpec matchers
- Clarify that we need Chef 12.1+

## 1.1.0 (2016-08-30)

- Added test Kitchen support with kitchen-wpar
- Added new wpar custom resource and wpar recipe
- Added new volume_group custom resource
- Added new pagingspace custom resource
- Added chef_version to the metadata and clarified that we require Chef 12+
- Added -U to chdev (hot_change parameter)
- Fixed chomp on nil error
- Fixed hash key symbol not found error
- Fixed errors from parsing inetd.conf
- Fixing minor bug for follows attribute
- Fixed bug in niminit remove action
- Added integration testing with kitchen-wpar
- Added linting with Cookstyle and resolved warnings

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
