#
# Copyright 2016, International Business Machines Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'pathname'
require 'open-uri'
require 'fileutils'

include AIX::PatchMgmt

property :targets, String, default: 'master'
property :apar, ['sec', 'hiper', nil], default: nil
property :filesets, String
property :csv, String
property :verbose, [true, false], default: false

default_action :patch

load_current_value do
end

action :install do
  cmd = Mixlib::ShellOut.new('which unzip')
  cmd.valid_exit_codes = 0
  cmd.run_command
  unless !cmd.error?
    # download unzip
    remote_file "#{Chef::Config[:file_cache_path]}/unzip-6.0-3.aix6.1.ppc.rpm" do
      source 'https://public.dhe.ibm.com/aix/freeSoftware/aixtoolbox/RPMS/ppc/unzip/unzip-6.0-3.aix6.1.ppc.rpm'
    end

    # install unzip
    execute "rpm -i #{Chef::Config[:file_cache_path]}/unzip-6.0-3.aix6.1.ppc.rpm" do
    end
  end

  unless ::File.exist?('/usr/bin/flrtvc.ksh')
    name = 'FLRTVC-0.7.zip'
    # download flrtvc
    remote_file "#{Chef::Config[:file_cache_path]}/#{name}" do
      source "https://www-304.ibm.com/webapp/set2/sas/f/flrt3/#{name}"
    end

    # unzip flrtvc
    execute "unzip -f #{Chef::Config[:file_cache_path]}/#{name} -d /usr/bin" do
    end
  end

  # set execution mode
  file '/usr/bin/flrtvc.ksh' do
    mode '0755'
  end
end

class FlrtvcNotFound < StandardError
end

class InvalidAparProperty < StandardError
end

class InvalidFilesetsProperty < StandardError
end

class InvalidCsvProperty < StandardError
end

def check_flrtvc
  raise FlrtvcNotFound unless ::File.exist?('/usr/bin/flrtvc.ksh')
end

def validate_targets(targets)
  clients = Mixlib::ShellOut.new("lsnim -t standalone | cut -d' ' -f1 | sort").run_command.stdout.split
  selected_machines = []
  targets.split(/[,\s]/).each do |machine|
    # expand wildcard
    machine.gsub!(/\*/, '.*?')
    clients.each do |m|
      selected_machines.concat(m.split) if m =~ /^#{machine}$/
    end
  end
  selected_machines = selected_machines.sort.uniq
  if selected_machines.empty?
    raise InvalidTargetsProperty, "Error: cannot contact any machines in '#{targets}'"
  end
  selected_machines
end

def validate_apar(apar)
  if apar.nil?
    ''
  elsif apar =~ /(sec|hiper)/
    "-t #{apar}"
  else
    raise InvalidAparProperty
  end
end

def validate_filesets(filesets)
  if filesets.nil?
    ''
  else
    "-g #{filesets}"
  end
end

def validate_csv(csv)
  if csv.nil?
    ''
  elsif Pathname(csv).absolute? && ::File.exist?(csv)
    "-f #{csv}"
  else
    raise InvalidCsvProperty
  end
end

def parse_report(s)
  urls = []
  s.each_line do |line|
    if line =~ /Download:\s+(https:\/\/aix.software.ibm.com\/aix\/efixes\/(security|hiper)\/.*?.tar)/
      urls.push(Regexp.last_match(1))
    end
  end
  urls
end

def download(url, path)
  ::File.open(path, 'w') do |f|
    ::IO.copy_stream(open(url), f)
  end
end

action :patch do
  # inputs
  Chef::Log.debug("targets=#{targets}")
  Chef::Log.debug("apar=#{apar}")
  Chef::Log.debug("filesets=#{filesets}")
  Chef::Log.debug("csv=#{csv}")

  check_flrtvc

  # build list of targets
  target_list = validate_targets(targets)
  Chef::Log.debug("target_list: #{target_list}")

  # check other properties
  apar_s = validate_apar(apar)
  Chef::Log.debug("apar_s: #{apar_s}")

  filesets_s = validate_filesets(filesets)
  Chef::Log.debug("filesets_s: #{filesets_s}")

  csv_s = validate_csv(csv)
  Chef::Log.debug("csv_s: #{csv_s}")

  # loop on clients
  target_list.each do |m|
    if m == 'master'
      # local target
      # TODO : replace c_rsh with local command
    else
      # oslevel
      oslevel = shell_out!("/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{m} \"/bin/oslevel -s\"").stdout.split('-')
      aix_level = oslevel[0][0]
      rel_level = oslevel[0][1]
      tl_level  = oslevel[1].to_i.to_s
      Chef::Log.debug(aix_level + '.' + rel_level + '.' + tl_level)

      # execute lslpp -Lcq
      lslpp_file = "#{Chef::Config[:file_cache_path]}/lslpp_#{m}.txt"
      shell_out!("/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{m} \"/usr/bin/lslpp -Lcq\" > #{lslpp_file}")

      # execute emgr -lv3
      emgr_file = "#{Chef::Config[:file_cache_path]}/emgr_#{m}.txt"
      shell_out!("/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{m} \"/usr/sbin/emgr -lv3\" > #{emgr_file}")
    end

    # execute flrtvc script
    flrtvc_out = shell_out!("/usr/bin/flrtvc.ksh -v -l #{lslpp_file} -e #{emgr_file} #{apar_s} #{filesets_s} #{csv_s}").stdout
    Chef::Log.debug(flrtvc_out)
    puts "\n" + flrtvc_out if verbose

    # clean temporary files
    ::File.delete(lslpp_file)
    ::File.delete(emgr_file)

    # parse report
    urls = parse_report(flrtvc_out)
    Chef::Log.debug("urls: #{urls}")

    unless urls.empty?
      # create directory
      lpp_source = "#{m}-lpp_source"
      lpp_source_base_dir = "#{Chef::Config[:file_cache_path]}/#{lpp_source}"
      lpp_source_dir = lpp_source_base_dir + '/emgr/ppc'
      unless ::File.directory?(lpp_source_dir)
        converge_by("create directory '#{lpp_source_dir}'") do
          ::FileUtils.mkdir_p(lpp_source_dir)
        end
      end

      # download fixes, untar it, and copy files to lpp source location
      urls.each do |url|
        converge_by("download '#{url}', untar, and copy content to '#{lpp_source_dir}'") do
          filename = Chef::Config[:file_cache_path] + '/' + url.split('/')[-1]
          dir_name = Chef::Config[:file_cache_path] + '/' + url.split('/')[-1].split('.')[0]
          # download
          download(url, filename)
          # untar
          shell_out!("/bin/tar -xf #{filename} -C #{Chef::Config[:file_cache_path]} `tar -tf #{filename} | grep epkg.Z$`")
          # filter oslevel
          ::Dir.glob(dir_name + '/*.epkg.Z').each do |f|
            so = shell_out("/usr/sbin/emgr -v3 -d -e #{f} 2>&1 | grep -p \\\"PREREQ | egrep \"0*#{aix_level}.0*#{rel_level}.0*#{tl_level}\"")
            if so.stdout =~ /^(.*?) (.*?) (.*?)$/
              level = OsLevel.new(aix_level, rel_level, tl_level)
              min_a = Regexp.last_match(2).split('.')
              min = OsLevel.new(min_a[0], min_a[1], min_a[2])
              max_a = Regexp.last_match(3).split('.')
              max = OsLevel.new(max_a[0], max_a[1], max_a[2])
              if min <= level && level <= max
                # copy efix
                ::FileUtils.cp_r(f, lpp_source_dir)
              end
            end
          end
          # clean temporary files
          ::FileUtils.remove_dir(dir_name)
          ::File.delete(filename)
        end
      end

      if m == 'master'
        # local target
        # TODO : replace nim with geninstall command
      else
        # create lpp source, patch and remove it
        converge_by("nim: perform synchronous software customization for client \'#{m}\' with resource \'#{lpp_source}\'") do
          nim = Nim.new
          nim.define_lpp_source(lpp_source, lpp_source_dir) unless nim.exist?(lpp_source)
          nim.perform_efix_customization(lpp_source, m)
          nim.remove_resource(lpp_source)
        end
      end

      # delete lpp source location
      ::FileUtils.remove_dir(lpp_source_base_dir)
    end
  end
end
