#
# Copyright:: 2016, International Business Machines Corporation
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
# DEFINITIONS
##############################
class FlrtvcNotFound < StandardError
end

class URLNotMatch < StandardError
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

def run_flrtvc(m, apar, filesets, csv, path, verbose)
  # check other properties
  apar_s = validate_apar(apar)
  Chef::Log.debug("apar_s: #{apar_s}")

  filesets_s = validate_filesets(filesets)
  Chef::Log.debug("filesets_s: #{filesets_s}")

  csv_s = validate_csv(csv)
  Chef::Log.debug("csv_s: #{csv_s}")

  lslpp_file = ::File.join(Chef::Config[:file_cache_path], "lslpp_#{m}.txt")
  emgr_file = ::File.join(Chef::Config[:file_cache_path], "emgr_#{m}.txt")

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
    flrtvc_file = ::File.join(path, "#{m}.flrtvc")
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

def fact(m, url, to, count, total)
  filename = nil
  raise URLNotMatch "link: #{url}" unless %r{^(?<protocol>.*?)://(?<srv>.*?)/(?<dir>.*)/(?<name>.*)$} =~ url

  # create directory to store downloads
  dir_name = ::File.join(to, dir.split('/')[-1])
  ::FileUtils.mkdir_p(dir_name) unless ::File.directory?(dir_name)

  if name.empty?
    #############################################
    # URL ends with /, look into that directory #
    #############################################
    case protocol
    when 'http', 'https'
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 10
      http.open_timeout = 10
      http.use_ssl = true if protocol.eql?('https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if protocol.eql?('https')
      req = Net::HTTP::Get.new(uri.request_uri)
      res = http.request(req)
      if res.is_a?(Net::HTTPResponse)
        found = false
        res.body.each_line do |l|
          next unless l =~ %r{<a href="(.*?.epkg.Z)">(.*?.epkg.Z)</a>}
          f = ::File.join(url, Regexp.last_match(1))
          path = ::File.join(dir_name, Regexp.last_match(1))

          # download file
          print "\033[2K\rDownloading #{count}/#{total} fixes. (#{f})"
          download(f, path)

          # check level prereq
          print "\033[2K\rChecking #{count}/#{total} fixes. (#{f})"
          next unless check_level_prereq?(m, path)

          print "... MATCH PREREQ\n"
          found = true
          filename = path
          break
        end
        print "... NO MATCH\n" unless found
      end
    when 'ftp'
      files = []
      Net::FTP.open(srv) do |ftp|
        ftp.login
        ftp.read_timeout = 300
        files = ftp.nlst(dir)
        found = false
        files.each do |file|
          f = ::File.join(url, ::File.basename(file))
          path = ::File.join(dir_name, ::File.basename(file))

          # download file
          print "\033[2K\rDownloading #{count}/#{total} fixes. (#{f})"
          ftp.getbinaryfile(file, path)

          # check level prereq
          print "\033[2K\rChecking #{count}/#{total} fixes. (#{f})"
          next unless check_level_prereq?(m, path)

          print "... MATCH PREREQ\n"
          found = true
          filename = path
          break
        end
        print "... NO MATCH\n" unless found
      end
    end

  elsif name.end_with?('.tar')
    #####################
    # URL is a tar file #
    #####################
    path = ::File.join(dir_name, name)

    # download file
    print "\033[2K\rDownloading #{count}/#{total} fixes. (#{url})"
    download(url, path)

    # untar
    print "\033[2K\rUntarring #{count}/#{total} fixes."
    untar(path, dir_name)

    # check level prereq
    found = false
    Dir.glob(::File.join(dir_name, url.split('/')[-1].split('.')[0], '*')).each do |f|
      print "\033[2K\rChecking #{count}/#{total} fixes. (#{url}:#{f.split('/')[-1]})"
      next unless check_level_prereq?(m, f)

      print "... MATCH PREREQ\n"
      found = true
      filename = f
      break
    end
    print "... NO MATCH\n" unless found

  elsif name.end_with?('.epkg.Z')
    #######################
    # URL is an efix file #
    #######################
    path = ::File.join(dir_name, name)

    # download file
    print "\033[2K\rDownloading #{count}/#{total} fixes. (#{url})"
    download(url, path)

    # check level prereq
    print "\033[2K\rChecking #{count}/#{total} fixes. (#{url})"
    if check_level_prereq?(m, path)
      print "... MATCH PREREQ\n"
      filename = path
    else
      print "... NO MATCH\n"
    end
  end
  filename
end

def download_and_check_fixes(m, urls, to)
  print "\n"
  count = 0
  total = urls.size
  urls.each do |item|
    fileset = item['Fileset']
    url = item['Download URL']
    count += 1
    dir = ::File.join(to, 'efixes', fileset)

    begin
      item['Filename'] = fact(m, url, dir, count, total)
    rescue StandardError => e
      Chef::Log.warn("An error of type '#{e.class}' happened while treating URL #{count}/#{total}: #{url}. Message is:\n#{e.message}")
      Chef::Log.warn('Retrying ...')
      item['Filename'] = fact(m, url, dir, count, total)
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
rescue StandardError => e
  Chef::Log.warn("Propagating exception of type '#{e.class}' when downloading!")
  raise e
end

def untar(src, dest)
  shell_out!("/bin/tar -xf #{src} -C #{dest} `/bin/tar -tf #{src} | /bin/grep epkg.Z$`", environment: { 'LANG' => 'C' })
rescue Mixlib::ShellOut::ShellCommandFailed => e
  if e.message =~ /No space left on device/
    increase_filesystem(dest)
    untar(src, dest)
  else
    Chef::Log.warn("Propagating exception of type '#{e.class}' when untarring!")
    raise e
  end
rescue StandardError => e
  Chef::Log.warn("Propagating exception of type '#{e.class}' when untarring!")
  raise e
end

def check_level_prereq?(machine, src)
  # get min/max level
  so = shell_out!("/usr/sbin/emgr -dXv3 -e #{src} | /bin/grep -p \\\"PREREQ", environment: { 'LANG' => 'C' }).stdout
  so.lines[3..-2].each do |line|
    Chef::Log.debug(line.to_s)
    next if line.start_with?('#') # skip comments
    next unless line =~ /^(.*?)\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+\.\d+\.\d+\.\d+)$/

    lslpp_file = ::File.join(Chef::Config[:file_cache_path], "lslpp_#{machine}.txt")
    ref = shell_out!("/bin/cat #{lslpp_file} | /bin/grep -w #{Regexp.last_match(1)} | /bin/cut -d: -f3", environment: { 'LANG' => 'C' }).stdout
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
rescue StandardError => e
  Chef::Log.warn("Propagating exception of type '#{e.class}' when checking!")
  raise e
end

##############################
# ACTION: install
##############################
action :install do
  if shell_out('which unzip').error?
    unzip_file = ::File.join(Chef::Config[:file_cache_path], 'unzip-6.0-3.aix6.1.ppc.rpm')

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
      only_if { new_resource.clean == true }
    end
  end

  unless ::File.exist?('/usr/bin/flrtvc.ksh')
    name = 'FLRTVC-latest.zip'
    flrtvc_file = ::File.join(Chef::Config[:file_cache_path], name)
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
      only_if { new_resource.clean == true }
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
  Chef::Log.debug("targets=#{new_resource.targets}")
  Chef::Log.debug("apar=#{new_resource.apar}")
  Chef::Log.debug("filesets=#{new_resource.filesets}")
  Chef::Log.debug("csv=#{new_resource.csv}")
  Chef::Log.debug("path=#{new_resource.path}")

  check_flrtvc

  puts ''

  # create directory based on date/time
  base_dir = ::File.join(Chef::Config[:file_cache_path], Time.now.to_s.gsub(/[:\s-]/, '_'))
  ::FileUtils.mkdir_p(base_dir)

  # build list of targets
  so = shell_out("lsnim -t standalone | cut -d' ' -f1 | sort").stdout.split
  so.concat shell_out("lsnim -t vios | cut -d' ' -f1 | sort").stdout.split
  target_list = expand_targets(new_resource.targets, so)
  Chef::Log.debug("target_list: #{target_list}")

  # loop on clients
  target_list.each do |m|
    # run flrtvc
    begin
      out = run_flrtvc(m, new_resource.apar, new_resource.filesets, new_resource.csv, new_resource.path, new_resource.verbose)
    rescue Mixlib::ShellOut::ShellCommandFailed => e
      Chef::Log.warn("[#{m}] Cannot be contacted")
      next # target unreachable
    end

    # parse report
    urls = parse_report_csv(m, out)
    Chef::Log.info("urls: #{urls}")
    if urls.empty?
      Chef::Log.warn("[#{m}] Does not have known vulnerabilities")
      next # target up-to-date
    end

    next if new_resource.check_only == true

    # download and check fixes
    efixes = download_and_check_fixes(m, urls, base_dir)
    Chef::Log.debug("efixes: #{efixes}")
    if efixes.empty?
      Chef::Log.warn("[#{m}] Have #{urls.size} vulnerabilities but none meet pre-requisites")
      next
    end

    next if new_resource.download_only == true

    # create lpp source directory
    lpp_source = "#{m}-lpp_source"
    lpp_source_base_dir = ::File.join(base_dir, 'lpp_sources', lpp_source)
    lpp_source_dir = ::File.join(lpp_source_base_dir, 'emgr', 'ppc')
    unless ::File.directory?(lpp_source_dir)
      converge_by("create directory '#{lpp_source_dir}'") do
        ::FileUtils.mkdir_p(lpp_source_dir)
      end
    end

    # copy efix
    efixes_basenames = []
    efixes.each do |efix|
      # build the efix basenames array
      basename = efix['Filename'].split('/')[-1]
      efixes_basenames << basename
      converge_by("[#{m}] #{efix['Type']} fix '#{basename}' meets level pre-requisite for fileset '#{efix['Fileset']}'") do
        begin
          ::FileUtils.cp_r(efix['Filename'], lpp_source_dir)
        rescue Errno::ENOSPC
          increase_filesystem(lpp_source_dir)
          ::FileUtils.cp_r(efix['Filename'], lpp_source_dir)
        end
      end
    end
    # sort the efix basenames array
    efixes_basenames.sort! { |x, y| y <=> x }

    if m == 'master'
      # install package
      converge_by("geninstall: install all efixes from '#{lpp_source_base_dir}'") do
        puts "\nStart patching nim master or local machine."
        geninstall_s = "/usr/sbin/geninstall -d #{lpp_source_base_dir} #{efixes_basenames.join(' ')}"
        exit_status = Open3.popen3({ 'LANG' => 'C' }, geninstall_s) do |_stdin, stdout, stderr, wait_thr|
          stdout.each_line do |line|
            line.chomp!
            print "\033[2K\r#{line}" if line =~ /^Processing Efix Package [0-9]+ of [0-9]+.$/
            puts "\n#{line}" if line =~ /^EPKG NUMBER/
            puts line if line =~ /^===========/
            puts "\033[0;31m#{line}\033[0m" if line =~ /INSTALL.*?FAILURE/
            puts "\033[0;32m#{line}\033[0m" if line =~ /INSTALL.*?SUCCESS/
            Chef::Log.info("[STDOUT] #{line}")
          end
          stderr.each_line do |line|
            line.chomp!
            warn line
            Chef::Log.info("[STDERR] #{line}")
          end
          wait_thr.value # Process::Status object returned.
        end
        puts "\nFinish patching nim master or local machine."
        Chef::Log.warn("[#{m}] Failed installing some efixes. See /var/adm/ras/emgr.log for details") unless exit_status.success?
      end
    elsif m =~ /vios/
      # create lpp source, patch and remove it
      converge_by("nim: perform synchronous software customization for vios \'#{m}\' with resource \'#{lpp_source}\'") do
        nim = Nim.new
        nim.define_lpp_source(lpp_source, lpp_source_base_dir) unless nim.exist?(lpp_source)
        begin
          nim.perform_efix_vios_customization(lpp_source, m, efixes_basenames.join(' '))
        rescue NimCustError => e
          warn e.message
          Chef::Log.warn("[#{m}] Failed installing some efixes. See /var/adm/ras/emgr.log on #{m} for details")
        end
        nim.remove_resource(lpp_source) if new_resource.clean == true
      end
    else
      # create lpp source, patch and remove it
      converge_by("nim: perform synchronous software customization for client \'#{m}\' with resource \'#{lpp_source}\'") do
        nim = Nim.new
        nim.define_lpp_source(lpp_source, lpp_source_base_dir) unless nim.exist?(lpp_source)
        begin
          nim.perform_efix_customization(lpp_source, m, efixes_basenames.join(' '))
        rescue NimCustError => e
          warn e.message
          Chef::Log.warn("[#{m}] Failed installing some efixes. See /var/adm/ras/emgr.log on #{m} for details")
        end
        nim.remove_resource(lpp_source) if new_resource.clean == true
      end
    end
  end # end targets

  # clean temporary files
  ::FileUtils.remove_dir(base_dir) if new_resource.clean == true
end
