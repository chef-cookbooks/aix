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
require 'net/https'
require 'net/ftp'
require 'csv'

include AIX::PatchMgmt

##############################
# PROPERTIES
##############################
property :targets, String, default: 'master'
property :apar, ['sec', 'hiper', 'all', nil], default: nil
property :filesets, String
property :csv, String
property :path, String
property :verbose, [true, false], default: false
property :clean, [true, false], default: true
property :check_only, [true, false], default: false
property :download_only, [true, false], default: false

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
  return '' if apar.nil? || apar.eql?('all')
  return "-t #{apar}" if apar =~ /(sec|hiper)/
  raise InvalidAparProperty
end

def validate_filesets(filesets)
  return '' if filesets.nil?
  "-g #{filesets}"
end

def validate_csv(csv)
  return '' if csv.nil?
  return "-f #{csv}" if Pathname(csv).absolute? && ::File.exist?(csv)
  raise InvalidCsvProperty
end

def increase_filesystem(path)
  mounts = []
  node['filesystem'].each_value do |v|
    mounts << v['mount']
  end
  # get longest match
  mount = mounts.sort_by!(&:length).reverse!.detect { |mnt| path =~ /#{Regexp.quote(mnt.to_s)}/ }
  so = shell_out!("/usr/sbin/chfs -a size=+100M #{mount}")
  Chef::Log.warn(so.stdout.chomp)
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

  # execute both compact and verbose flrtvc script
  out_c = shell_out!("/usr/bin/flrtvc.ksh -l #{lslpp_file} -e #{emgr_file} #{apar_s} #{filesets_s} #{csv_s}", environment: { 'LANG' => 'C' }).stdout
  out_v = shell_out!("/usr/bin/flrtvc.ksh -l #{lslpp_file} -e #{emgr_file} #{apar_s} #{filesets_s} #{csv_s} -v", environment: { 'LANG' => 'C' }).stdout

  # write report file
  unless path.nil?
    ::FileUtils.mkdir_p(path) unless ::File.directory?(path)
    flrtvc_file = "#{path}/#{m}.flrtvc"
    ::IO.write(flrtvc_file, verbose == true ? out_v : out_c)
    Chef::Log.warn("[#{m}] Flrtvc report has been saved to '#{flrtvc_file}'")
  end

  # display in verbose mode
  puts out_v if verbose

  # clean temporary files
  #::File.delete(lslpp_file) if clean == true
  #::File.delete(emgr_file) if clean == true

  out_c
end

def parse_report_csv(m, s)
  # ### BUG FLRTVC WORKAROUND ###
  # s.each_line do |line|
  #   s.delete!(line) if line =~ /Not connected./
  # end
  # ######### END ###############
  Chef::Log.debug("s = #{s}")
  csv = CSV.new(s, headers: true, col_sep: '|')
  arr = csv.to_a.map(&:to_hash)
  Chef::Log.debug("csv = #{arr}")
  filesets = []
  arr.each do |url|
    filesets << url['Fileset']
  end
  filesets.uniq!
  urls = arr.select { |url| url['Download URL'] =~ %r{^(http|https|ftp)://(aix.software.ibm.com|public.dhe.ibm.com)/(aix/ifixes/.*?/|aix/efixes/security/.*?.tar)$} }
  # remove duplicates and sort reverse order to have more recent ones first.
  urls.uniq! { |url| url['Download URL'] } unless urls.empty?
  urls.sort! { |a, b| a['Download URL'] <=> b['Download URL'] } unless urls.empty?
  urls.reverse! unless urls.empty?
  Chef::Log.debug("urls = #{urls}")
  Chef::Log.warn("[#{m}] Found #{urls.size} different download links over #{arr.size} vulnerabilities and #{filesets.size} filesets")
  urls
end

def download_and_check_fixes(m, urls, to)
  print "\n"
  count = 0
  total = urls.size
  urls.each do |item|
    fileset = item['Fileset']
    url = item['Download URL']
    count += 1

    begin
      if %r{^(?<protocol>.*?)://(?<srv>.*?)/(?<dir>.*)/$} =~ url
        dir_name = to + '/efixes/' + fileset + '/' + url.split('/')[-1]
        ::FileUtils.mkdir_p(dir_name) unless ::File.directory?(dir_name)
        case protocol
        when 'http'
          uri = URI(url)
          ### 1
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = 10
          http.open_timeout = 10
          req = Net::HTTP::Get.new(uri.request_uri)
          res = http.request(req)
          ### 2
          #http = Net::HTTP.new(uri.host, uri.port)
          #http.read_timeout = 10
          #http.open_timeout = 10
          #res = http.start() { |http| http.get(uri.path) }
          ### 3
          #res = Net::HTTP.get_response(uri)
          ###
          if res.kind_of?(Net::HTTPResponse)
            found = false
            res.body.each_line do |l|
              next unless l =~ %r{<a href="(.*?.epkg.Z)">(.*?.epkg.Z)</a>}
              filename = url + Regexp.last_match(1)
              path = dir_name + '/' + Regexp.last_match(1)

              # download file
              print "\033[2K\rDownloading #{count}/#{total} fixes. (#{filename})"
              download(filename, path)

              # check level prereq
              print "\033[2K\rChecking #{count}/#{total} fixes. (#{filename})"
              next unless check_level_prereq?(m, path)

              print "... MATCH PREREQ\n"
              found = true
              item['Filename'] = path
              break
            end
            print "... NO MATCH\n" unless found
          end
        when 'https'
          uri = URI(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = 10
          http.open_timeout = 10
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          req = Net::HTTP::Get.new(uri.request_uri)
          res = http.request(req)
          if res.kind_of?(Net::HTTPResponse)
            found = false
            res.body.each_line do |l|
              next unless l =~ %r{<a href="(.*?.epkg.Z)">(.*?.epkg.Z)</a>}
              filename = url + Regexp.last_match(1)
              path = dir_name + '/' + Regexp.last_match(1)

              # download file
              print "\033[2K\rDownloading #{count}/#{total} fixes. (#{filename})"
              download(filename, path)

              # check level prereq
              print "\033[2K\rChecking #{count}/#{total} fixes. (#{filename})"
              next unless check_level_prereq?(m, path)

              print "... MATCH PREREQ\n"
              found = true
              item['Filename'] = path
              break
            end
            print "... NO MATCH\n" unless found
          end
        when 'ftp'
          ftp = Net::FTP.new
          ftp.connect(srv)
          ftp.login
          ftp.chdir(dir)
          files = ftp.nlst
          ftp.close
          found = false
          files.each do |file|
            filename = url + file
            path = dir_name + '/' + file

            # download file
            print "\033[2K\rDownloading #{count}/#{total} fixes. (#{filename})"
            download(filename, path)

            # check level prereq
            print "\033[2K\rChecking #{count}/#{total} fixes. (#{filename})"
            next unless check_level_prereq?(m, path)

            print "... MATCH PREREQ\n"
            found = true
            item['Filename'] = path
            break
          end
          print "... NO MATCH\n" unless found
        end
      elsif url.end_with?('.tar')
        dir_name = to + '/efixes/' + fileset + '/' + url.split('/')[-2]
        ::FileUtils.mkdir_p(dir_name) unless ::File.directory?(dir_name)
        path = dir_name + '/' + url.split('/')[-1]

        # download file
        print "\033[2K\rDownloading #{count}/#{total} fixes. (#{url})"
        download(url, path)

        # untar
        print "\033[2K\rUntarring #{count}/#{total} fixes."
        untar(path, dir_name)

        # check level prereq
        found = false
        Dir.glob(dir_name + '/' + url.split('/')[-1].split('.')[0] + '/*').each do |f|
          print "\033[2K\rChecking #{count}/#{total} fixes. (#{url}:#{f.split('/')[-1]})"
          next unless check_level_prereq?(m, f)

          print "... MATCH PREREQ\n"
          found = true
          item['Filename'] = f
          break
        end
        print "... NO MATCH\n" unless found
      elsif url.end_with?('.epkg.Z')
        dir_name = to + '/efixes/' + fileset + '/' + url.split('/')[-2]
        ::FileUtils.mkdir_p(dir_name) unless ::File.directory?(dir_name)
        path = dir_name + '/' + url.split('/')[-1]

        # download file
        print "\033[2K\rDownloading #{count}/#{total} fixes. (#{url})"
        download(url, path)

        # check level prereq
        print "\033[2K\rChecking #{count}/#{total} fixes. (#{url})"
        if check_level_prereq?(m, path)
          print "... MATCH PREREQ\n"
          item['Filename'] = path
        else
          print "... NO MATCH\n"
        end
      end
    rescue Exception => e
      Chef::Log.warn("An error of type '#{e.class}' happened, message is '#{e.message}' while treating URL: #{url}")
    end
  end # end urls
  print "\n"
  urls.reject! { |url| url['Filename'].nil? }
  Chef::Log.debug("urls = #{urls}")
  Chef::Log.warn("[#{m}] Found #{urls.size} fixes to install")
  urls
end

def download(src, dst)
  unless ::File.exist?(dst)
    ::File.open(dst, 'w') do |f|
      ::IO.copy_stream(open(src), f)
    end
  end
rescue Errno::ENOSPC
  increase_filesystem(dst)
  ::File.delete(dst)
  download(src, dst)
end

def untar(src, dest)
  shell_out!("/bin/tar -xf #{src} -C #{dest} `/bin/tar -tf #{src} | /bin/grep epkg.Z$`")
rescue Mixlib::ShellOut::ShellCommandFailed => e
  increase_filesystem(dest) if e.message =~ /No space left on device/
  shell_out("/bin/tar -xf #{src} -C #{dest} `/bin/tar -tf #{src} | /bin/grep epkg.Z$`")
end

def check_level_prereq?(machine, src)
  # get min/max level
  so = shell_out!("/usr/sbin/emgr -v3 -d -e #{src} 2>&1 | /bin/grep -p \\\"PREREQ", environment: { 'LANG' => 'C' }).stdout
  so.lines[3..-2].each do |line|
    Chef::Log.debug(line.to_s)
    return false unless line =~ /^(.*?)\s+(.*?)\s+(.*?)$/

    # get actual level
    #if machine.eql?('master')
    #  ref = shell_out!("/bin/lslpp -Lcq #{Regexp.last_match(1)} | /bin/cut -d: -f3", environment: { 'LANG' => 'C' }).stdout
    #else
    #  ref = shell_out!("/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{machine} \"/bin/lslpp -Lcq #{Regexp.last_match(1)} | /bin/cut -d: -f3\"", environment: { 'LANG' => 'C' }).stdout
    #end
    ref = shell_out!("/bin/cat #{Chef::Config[:file_cache_path]}/lslpp_#{machine}.txt | /bin/grep -w #{Regexp.last_match(1)} | /bin/cut -d: -f3\"", environment: { 'LANG' => 'C' }).stdout
    lvl_a = ref.split('.')
    lvl = SpLevel.new(lvl_a[0], lvl_a[1], lvl_a[2], lvl_a[3])

    min_a = Regexp.last_match(2).split('.')
    min = SpLevel.new(min_a[0], min_a[1], min_a[2], min_a[3])
    max_a = Regexp.last_match(3).split('.')
    max = SpLevel.new(max_a[0], max_a[1], max_a[2], max_a[3])
    Chef::Log.debug("#{src}: #{lvl} #{min} #{max}")
    return false unless min <= lvl && lvl <= max
  end
  true
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
    name = 'FLRTVC-latest.zip'
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
  Chef::Log.debug("path=#{path}")

  check_flrtvc

  # create directory based on date/time
  base_dir = "#{Chef::Config[:file_cache_path]}/#{Time.now.to_s.gsub(/[:\s-]/, '_')}"
  ::FileUtils.mkdir_p(base_dir)

  # build list of targets
  so = Mixlib::ShellOut.new("lsnim -t standalone | cut -d' ' -f1 | sort").run_command.stdout.split
  so.concat Mixlib::ShellOut.new("lsnim -t vios | cut -d' ' -f1 | sort").run_command.stdout.split
  target_list = expand_targets(targets, so)
  Chef::Log.debug("target_list: #{target_list}")

  # loop on clients
  target_list.each do |m|
    # run flrtvc
    begin
      out = run_flrtvc(m)
    rescue Mixlib::ShellOut::ShellCommandFailed => e
      Chef::Log.warn("#{m} cannot be contacted")
      next # target unreachable
    end

    # parse report
    urls = parse_report_csv(m, out)
    Chef::Log.info("urls: #{urls}")
    if urls.empty?
      Chef::Log.warn("#{m} does not have known vulnerabilities")
      next # target up-to-date
    end

    next if check_only == true

    # download and check fixes
    efixes = download_and_check_fixes(m, urls, base_dir)
    Chef::Log.debug("efixes: #{efixes}")
    if efixes.empty?
      Chef::Log.warn("#{m} have #{urls.size} vulnerabilities but none meet pre-requisites")
      next
    end

    next if download_only == true

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
      converge_by("[#{m}] #{efix['Type']} fix '#{efix['Filename'].split('/')[-1]}' meets level pre-requisite for fileset '#{efix['Fileset']}'") do
        begin
          ::FileUtils.cp_r(efix['Filename'], lpp_source_dir)
        rescue Errno::ENOSPC
          increase_filesystem(lpp_source_dir)
          ::FileUtils.cp_r(efix['Filename'], lpp_source_dir)
        end
      end
    end

    if m == 'master'
      # install package
      converge_by("geninstall: install all efixes from '#{lpp_source_dir}'") do
        so = shell_out("/usr/sbin/geninstall -d #{lpp_source_dir} all")
        puts ''
        so.stdout.each_line do |line|
          line.chomp!
          #print "\033[2K\r#{line}" if line =~ /^Processing Efix Package [0-9]+ of [0-9]+.$/
          puts "\n#{line}" if line =~ /^EPKG NUMBER/
          puts line if line =~ /^===========/
          puts "\033[0;31m#{line}\033[0m" if line =~ /INSTALL.*?FAILURE/
          puts "\033[0;32m#{line}\033[0m" if line =~ /INSTALL.*?SUCCESS/
          Chef::Log.info("[STDOUT] #{line}")
        end
        so.stderr.each_line do |line|
          Chef::Log.info("[STDERR] #{line.chomp}")
        end
        if so.error?
          # STDERR.puts so.stderr
          Chef::Log.warn("#{m} failed installing some efixes. See /var/adm/ras/emgr.log for details")
        end
      end
    else
      # create lpp source, patch and remove it
      converge_by("nim: perform synchronous software customization for client \'#{m}\' with resource \'#{lpp_source}\'") do
        nim = Nim.new
        nim.define_lpp_source(lpp_source, lpp_source_dir) unless nim.exist?(lpp_source)
        begin
          nim.perform_efix_customization(lpp_source, m)
        rescue NimCustError => e
          STDERR.puts e.message
          Chef::Log.warn("#{m} failed installing some efixes. See /var/adm/ras/emgr.log on #{m} for details")
        end
        nim.remove_resource(lpp_source) if clean == true
      end
    end
  end # end targets

  # clean temporary files
  ::FileUtils.remove_dir(base_dir) if clean == true
end
