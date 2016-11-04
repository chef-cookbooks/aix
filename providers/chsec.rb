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

use_inline_resources

# support whyrun
def whyrun_supported?
  true
end

# Run lssec, return fale if command fails, otherwise return the current value
def lssec(file, stanza, attribute)
  cmd = shell_out("lssec -c -f '#{file}' -s '#{stanza}' -a '#{attribute}'")
  if cmd.error?
    Chef::Log.debug(
      "lssec: attribute '#{attribute}' not found in #{file}:#{stanza}"
    )
    return false
  end
  cmd.stdout.split(/\n/).last.split(':', 2).last
end

def load_current_resource
  current_attributes = {}
  nr = @new_resource
  @current_resource = Chef::Resource::AixChsec.new(nr.name)

  nr.attributes.each_key do |key|
    current_value = lssec(nr.file_name, nr.stanza, key)
    current_attributes[key] = current_value if current_value
  end

  @current_resource.attributes(current_attributes)
end

# return list of changed attributes, empty list otherwise
def changed_attributes
  changed            = []
  new_attributes     = @new_resource.attributes
  current_attributes = @current_resource.attributes

  new_attributes.each_key do |key, value|
    changed << key unless current_attributes[key.to_sym] == value
  end

  changed
end

# update action
action :update do
  nr = @new_resource
  chsec_attrs = []
  chsec_prefix = \
    "chsec -f '#{@new_resource.file_name}' -s '#{new_resource.stanza}'"
  changed_attribute_keys = changed_attributes

  changed_attributes.each do |key|
    chsec_attrs << "-a '#{key}'='#{nr.attributes[key]}'"
  end

  unless chsec_attrs.empty?
    chsec = "#{chsec_prefix} #{chsec_attrs.join(' ')}"
    converge_by chsec do
      shell_out!(chsec)
    end
  end
end
