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
require 'net/http'
require 'net/ftp'

include AIX::PatchMgmt

##############################
# PROPERTIES
##############################
property :targets, String, default: 'master'
property :apar, ['sec', 'hiper', nil], default: nil
property :filesets, String
property :csv, String
property :verbose, [true, false], default: false
property :clean, [true, false], default: true
property :check_only, [true, false], default: false

default_action :patch

##############################
# load_current_value
##############################
load_current_value do
end

##############################
# DEFINITIONS
##############################
class FlrtvcNotFound < StandardError
end

class InvalidAparProperty < StandardError
end

class InvalidCsvProperty < StandardError
end

def check_flrtvc
  raise FlrtvcNotFound unless ::File.exist?('/usr/bin/flrtvc.ksh')
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

  class ::Hash
    def deep_merge(second)
        merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
        self.merge(second, &merger)
    end
  end

def run_flrtvc(m)
  # check other properties
  apar_s = validate_apar(apar)
  Chef::Log.debug("apar_s: #{apar_s}")

  filesets_s = validate_filesets(filesets)
  Chef::Log.debug("filesets_s: #{filesets_s}")

  csv_s = validate_csv(csv)
  Chef::Log.debug("csv_s: #{csv_s}")

  lslpp_file = "#{Chef::Config[:file_cache_path]}/lslpp_#{m}.txt"
  emgr_file = "#{Chef::Config[:file_cache_path]}/emgr_#{m}.txt"
  flrtvc_file = "#{Chef::Config[:file_cache_path]}/flrtvc_#{m}.txt"

  if m == 'master'
    # execute lslpp -Lcq
    shell_out!("/usr/bin/lslpp -Lcq > #{lslpp_file}")
    # execute emgr -lv3
    shell_out!("/usr/sbin/emgr -lv3 > #{emgr_file}")
  else
    # execute lslpp -Lcq
    shell_out!("/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{m} \"/usr/bin/lslpp -Lcq\" > #{lslpp_file}")
    # execute emgr -lv3
    shell_out!("/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{m} \"/usr/sbin/emgr -lv3\" > #{emgr_file}")
  end

  # execute flrtvc script
  shell_out!("/usr/bin/flrtvc.ksh -l #{lslpp_file} -e #{emgr_file} #{apar_s} #{filesets_s} #{csv_s} > #{flrtvc_file}", environment: { 'LANG' => 'C' })
  out = ::IO.read(flrtvc_file)
  if verbose
    puts
    puts shell_out!("/usr/bin/flrtvc.ksh -l #{lslpp_file} -e #{emgr_file} #{apar_s} #{filesets_s} #{csv_s} -v", environment: { 'LANG' => 'C' }).stdout
  end

  # clean temporary files
  ::File.delete(lslpp_file) if clean == true
  ::File.delete(emgr_file) if clean == true
  ::File.delete(flrtvc_file) if clean == true

  out
end
  
def parse_report_csv(s)
  csv = CSV.new(s, :headers => true, :col_sep => '|')
  arr = csv.to_a.map {|row| row.to_hash }
  filesets = []
  arr.each do |url|
    filesets << url['Fileset']
  end
  filesets.uniq!
  urls = arr.select { |url| url['Download URL'] =~ %r{(http|https|ftp)://(aix.software.ibm.com|public.dhe.ibm.com)(/aix/ifixes/.*?/|/aix/efixes/security/.*?.tar)} }
  urls.uniq! { |url| url['Download URL'] }
  Chef::Log.debug(urls)
  Chef::Log.warn("Found #{urls.size} different download links over #{arr.size} vulnerabilities and #{filesets.size} filesets")
  urls
end

def download_and_check_fixes(urls, to)
  print "\n"
  count = 0
  total = urls.size
  urls.each do |item|
    fileset = item['Fileset']
    url = item['Download URL']
    level = item['Current Version']
    count += 1

    if url =~ %r{^(.*?)://(.*?)/(.*)/$}
      dir_name = to + '/efixes/' + fileset + '/' + url.split('/')[-1]
      ::FileUtils.mkdir_p(dir_name) unless ::File.directory?(dir_name)
      protocol, srv, dir = Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3)
      case protocol
      when 'http', 'https'
        uri = URI(url)
        res = Net::HTTP.get_response(uri)
        if res.is_a?(Net::HTTPSuccess)
          res.body.each_line do |l|
            if l =~ %r{<a href="(.*?.epkg.Z)">(.*?.epkg.Z)</a>}
              filename = url + Regexp.last_match(1)
              path = dir_name + '/' + Regexp.last_match(1)
              # download file
              print "\033[2K\rDownloading #{count}/#{total} fixes. (#{filename})"
              download(filename, path)
              # check level prereq
              print "\033[2K\rChecking #{count}/#{total} fixes. (#{filename}) "
              if check_level_prereq?(path, level)
                print "... MATCH PREREQ\n"
                item['Filename'] = path
                break
              end
            end
          end
        end
      when 'ftp'
        ftp = Net::FTP::new
        ftp.connect(srv)
        ftp.login
        ftp.chdir(dir)
        files = ftp.nlst()
        ftp.close
        files.each do |file|
          filename = url + file
          path = dir_name + '/' + file
          # download file
          print "\033[2K\rDownloading #{count}/#{total} fixes. (#{filename})"
          download(filename, path)
          # check level prereq
          print "\033[2K\rChecking #{count}/#{total} fixes. (#{filename}) "
          if check_level_prereq?(path, level)
            print "... MATCH PREREQ\n"
            item['Filename'] = path
            break
          end
        end
      end
    elsif url.end_with?('.tar')
      dir_name = to + '/efixes/' + fileset + '/' + url.split('/')[-2]
      ::FileUtils.mkdir_p(dir_name) unless ::File.directory?(dir_name)
      path = dir_name + '/' + url.split('/')[-1]
      # download file
      print "\033[2K\rDownloading #{count}/#{total} fixes. (#{url})"
      download(url, path)
      # untar
      print "\033[2K\rUntarring #{count}/#{total} fixes.)"
      shell_out!("/bin/tar -xf #{path} -C #{dir_name} `tar -tf #{path} | grep epkg.Z$`")
      # check level prereq
      Dir.glob(dir_name + '/' + url.split('/')[-1].split('.')[0] + '/*').each do |f|
        print "\033[2K\rChecking #{count}/#{total} fixes. (#{url}:#{f.split('/')[-1]}) "
        if check_level_prereq?(f, level)
          print "... MATCH PREREQ\n"
          item['Filename'] = f
          break
        end
      end
    elsif url.end_with?('.epkg.Z')
      dir_name = to + '/efixes/' + fileset + '/' + url.split('/')[-2]
      ::FileUtils.mkdir_p(dir_name) unless ::File.directory?(dir_name)
      path = dir_name + '/' + url.split('/')[-1]
      # download file
      print "\033[2K\rDownloading #{count}/#{total} fixes. (#{url})"
      download(url, path)
      # check level prereq
      print "\033[2K\rChecking #{count}/#{total} fixes. (#{url}) "
      if check_level_prereq?(path, level)
        print "... MATCH PREREQ\n"
        item['Filename'] = path
        break
      end
    end
  end # end urls
  print "\n"
  urls.reject! { |url| url['Filename'].nil? }
  Chef::Log.debug(urls)
  Chef::Log.warn("Found #{urls.size} fixes to install")
  urls
end

def download(src, dst)
  ::File.open(dst, 'w') do |f|
    ::IO.copy_stream(open(src), f)
  end unless ::File.exist?(dst)
end

def check_level_prereq?(src, ref)
  # get actual level
  lvl_a = ref.split('.')
  lvl = SpLevel.new(lvl_a[0], lvl_a[1], lvl_a[2], lvl_a[3])
  
  # get min/max level
  so = shell_out("/usr/sbin/emgr -v3 -d -e #{src} 2>&1 | grep -p \\\"PREREQ | egrep \"0*#{lvl_a[0].to_i}.0*#{lvl_a[1].to_i}.0*#{lvl_a[2].to_i}\"", environment: { 'LANG' => 'C' }).stdout
  return false unless so =~ /^(.*?)\s+(.*?)\s+(.*?)$/

  min_a = Regexp.last_match(2).split('.')
  min = SpLevel.new(min_a[0], min_a[1], min_a[2], min_a[3])
  max_a = Regexp.last_match(3).split('.')
  max = SpLevel.new(max_a[0], max_a[1], max_a[2], max_a[3])
  #puts "#{src}: #{lvl} #{min} #{max}"
  return false unless min <= lvl && lvl <= max

  return true
end

##############################
# ACTION: install
##############################
action :install do
  if Mixlib::ShellOut.new('which unzip').run_command.error?
    unzip_file = "#{Chef::Config[:file_cache_path]}/unzip-6.0-3.aix6.1.ppc.rpm"

    # download unzip
    remote_file unzip_file.to_s do
      source 'https://public.dhe.ibm.com/aix/freeSoftware/aixtoolbox/RPMS/ppc/unzip/unzip-6.0-3.aix6.1.ppc.rpm'
    end

    # install unzip
    execute "rpm -i #{unzip_file}" do
    end

    # delete
    file unzip_file.to_s do
      action :delete
      only_if { clean == true }
    end
  end

  unless ::File.exist?('/usr/bin/flrtvc.ksh')
    name = 'FLRTVC-0.7.zip'
    flrtvc_file = "#{Chef::Config[:file_cache_path]}/#{name}"
    # download flrtvc
    remote_file flrtvc_file.to_s do
      source "https://www-304.ibm.com/webapp/set2/sas/f/flrt3/#{name}"
    end

    # unzip flrtvc
    execute "unzip -o #{flrtvc_file} -d /usr/bin" do
    end

    # delete
    file flrtvc_file.to_s do
      action :delete
      only_if { clean == true }
    end
  end

  # set execution mode
  file '/usr/bin/flrtvc.ksh' do
    mode '0755'
  end
end

##############################
# ACTION: patch
##############################
action :patch do
  # inputs
  Chef::Log.debug("targets=#{targets}")
  Chef::Log.debug("apar=#{apar}")
  Chef::Log.debug("filesets=#{filesets}")
  Chef::Log.debug("csv=#{csv}")

  check_flrtvc

  base_dir = "#{Chef::Config[:file_cache_path]}/#{Time.now.to_s.gsub(/[:\s-]/, '_')}"
  ::FileUtils.mkdir_p(base_dir)

  # build list of targets
  so = Mixlib::ShellOut.new("lsnim -t standalone | cut -d' ' -f1 | sort").run_command.stdout.split
  target_list = expand_targets(so)
  Chef::Log.debug("target_list: #{target_list}")

  # loop on clients
  target_list.each do |m|
    # run flrtvc
    begin
      out = run_flrtvc(m)
    rescue Exception => e
      Chef::Log.warn("#{m} cannot be contacted (#{e.message})")
      next # target unreachable
    end

    # parse report
    urls = parse_report_csv(out)
    Chef::Log.info("urls: #{urls}")
    if urls.empty?
      Chef::Log.warn("#{m} does not have known vulnerabilities")
      next # target up-to-date
    end

    next if check_only == true

    # download and check fixes
    efixes = download_and_check_fixes(urls, base_dir)
    Chef::Log.debug("efixes: #{efixes}")
    if efixes.empty?
      Chef::Log.warn("#{m} have #{urls.size} vulnerabilities but none meet pre-requisites")
      next
    end

    # create lpp source directory
    lpp_source = "#{m}-lpp_source"
    lpp_source_dir = base_dir + '/lpp_sources/' + lpp_source + '/emgr/ppc'
    unless ::File.directory?(lpp_source_dir)
      converge_by("create directory '#{lpp_source_dir}'") do
        ::FileUtils.mkdir_p(lpp_source_dir)
      end
    end

    # copy efix
    efixes.each do |efix|
      converge_by("[#{m}] #{efix['Type']} fix '#{efix['Filename'].split('/')[-1]}' meets level pre-requisite") do
        ::FileUtils.cp_r(efix['Filename'], lpp_source_dir)
      end
    end

    if m == 'master'
      # install package
      converge_by("geninstall: install all efixes from '#{lpp_source_dir}'") do
        begin
          shell_out!("/usr/sbin/geninstall -d #{lpp_source_dir} all")
        rescue
          Chef::Log.warn('failed installing some efixes. See /var/adm/ras/emgr.log for details')
          puts shell_out("cat /var/adm/ras/emgr.log | grep -p \"EPKG NUMBER\"").stdout
        end
      end
    else
      # create lpp source, patch and remove it
      converge_by("nim: perform synchronous software customization for client \'#{m}\' with resource \'#{lpp_source}\'") do
        nim = Nim.new
        nim.define_lpp_source(lpp_source, lpp_source_dir) unless nim.exist?(lpp_source)
        begin
          nim.perform_efix_customization(lpp_source, m)
        rescue Exception => e
          $stderr.puts e.message
          Chef::Log.warn("#{m} failed installing some efixes. See /var/adm/ras/emgr.log on #{m} for details")
        end
        nim.remove_resource(lpp_source) if clean == true
      end
    end
  end # end targets

  # clean temporary files
  ::FileUtils.remove_dir(base_dir) if clean == true
end
