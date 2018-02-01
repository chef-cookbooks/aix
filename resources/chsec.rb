#
# Copyright:: 2015-2016, Benoit Creau <benoit.creau@chmod666.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

property :file_name, String, name_property: true, identity: true
property :attributes, Hash, required: true
property :stanza, String, desired_state: false, required: true

##############################
# DEFINITIONS
##############################

# Run lssec and return value of requested attribute or false if command fails
def lssec(file, stanza, attribute)
  cmd = shell_out("lssec -c -f '#{file}' -s '#{stanza}' -a '#{attribute}'")
  if cmd.error?
    Chef::Log.debug("lssec: attribute '#{attribute}' not found in #{file}:#{stanza}")
    return false
  end
  cmd.stdout.split(/\n/).last.split(':', 2).last
end

def load_current_resource
  nr.attributes.each_key do |key|
    current_value = lssec(nr.file_name, nr.stanza, key)
    current_attributes[key] = current_value if current_value
    @current_resource.attributes(current_attributes)
  end
end

def changed_attributes
  changed = []
  new_attributes     = @new_resource.attributes
  current_attributes = @current_resource.attributes

  new_attributes.each_key do |key, value|
    changed << key unless current_attributes[key.to_sym] == value
  end

  changed
end

##############################
# DEFINITIONS
##############################

# Run lssec and return value of requested attribute or false if command fails
def lssec(file, stanza, attribute)
 cmd = shell_out("lssec -c -f '#{file}' -s '#{stanza}' -a '#{attribute}'")
 if cmd.error?
  Chef::Log.debug("lssec: attribute '#{attribute}' not found in #{file}:#{stanza}")
  return false
 end
 cmd.stdout.split(/\n/).last.split(':', 2).last
end
 
def load_current_resource
 new_res.attributes.each_key do |key|
 current_value = lssec(new_res.file_name, new_res.stanza, key)
 current_attributes[key] = current_value if current_value
 @current_resource.attributes(current_attributes)
 end
end
 
def changed_attributes
 changed            = []
 new_attributes     = @new_resource.attributes
 current_attributes = @current_resource.attributes
 
 new_attributes.each_key do |key, value|
 changed << key unless current_attributes[key.to_sym] == value
 end
 
 changed
end

load_current_value do |desired|
  # Check if file exists
  if ::File.exist?(desired.file_name)
    # check if the stanza exists
    # if the stanza does not exists the resource does not exist
    unless ::File.readlines(desired.file_name).grep(/#{desired.stanza}:/)
      Chef::Log.debug("chsec: no stanza found (#{desired.stanza})")
      current_value_does_not_exist!
    end
  else
    raise("chsec: #{desired.file_name} not found")
  end

  # we are loading resource this way
  # a file modified by chsec is like this
  # usw:
  #     shells = /bin/sh,/bin/bsh,/bin/csh,/bin/ksh,/bin/tsh,/bin/ksh93,/usr/bin/sh,/usr/bin/bsh,/usr/bin/csh,/usr/bin/ksh,/usr/bin/tsh,/usr/bin/ksh93,/usr/bin/rksh,/usr/bin/rksh93,/usr/sbin/uucp/uucico,/usr/sbin/sliplogin,/usr/sbin/snappd
  #     maxlogins = 32767
  #     logintimeout = 60
  #     maxroles = 8
  #     auth_type = STD_AUTH

  # Searching for the stanza
  found_stanza = false
  current_attributes = {}
  ::File.open(desired.file_name).each_line do |line|
    if line.chomp == "#{desired.stanza}:"
      Chef::Log.debug("chsec: found stanza (#{desired.stanza})")
      found_stanza = true
      next
    end
    # if we found the stanza, and we match another stanza found_stanza=0
    found_stanza = false if found_stanza && line =~ /\w:/
    # filling the hash table
    next unless found_stanza && line =~ /=/
    line_attribute = line.split('=')
    # chomp and strip here
    key = line_attribute[0].chomp.strip
    value = line_attribute[1].chomp.strip
    # to_sym very important
    current_attributes[key.to_sym] = value
    Chef::Log.debug("chsec: #{desired.stanza} -> [#{key}],[#{value}])")
  end
  # loading the attributes
  attributes current_attributes
end

# update action
action :update do
<<<<<<< HEAD
 new_res = @new_resource
 chsec_attrs = []
 chsec_prefix = \
 "chsec -f '#{@new_resource.file_name}' -s '#{new_resource.stanza}'"
 
 changed_attributes.each do |key|
 chsec_attrs << "-a '#{key}'='#{new_res.attributes[key]}'"
 end
 
 unless chsec_attrs.empty?
  chsec = "#{chsec_prefix} #{chsec_attrs.join(' ')}"
  converge_by chsec do
  shell_out!(chsec)
=======
  nr = @new_resource
  chsec_attrs = []
  chsec_prefix = \
    "chsec -f '#{@new_resource.file_name}' -s '#{new_resource.stanza}'"

  changed_attributes.each do |key|
    chsec_attrs << "-a '#{key}'='#{nr.attributes[key]}'"
>>>>>>> branch 'Chef13upgrade' of https://github.com/srctarget/aix.git
  end
<<<<<<< HEAD
 end
=======

  unless chsec_attrs.empty?
    chsec = "#{chsec_prefix} #{chsec_attrs.join(' ')}"
    converge_by chsec do
      shell_out!(chsec)
    end
  end
>>>>>>> branch 'Chef13upgrade' of https://github.com/srctarget/aix.git
end
