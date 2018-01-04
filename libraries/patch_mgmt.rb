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

module AIX
  module PatchMgmt
    include Chef::Mixin::ShellOut

    def clients(node)
      check_nim_info(node)
      nodes = Hash.new { |h, k| h[k] = {} }
      nodes['machine'] = node['nim']['clients'].keys
      nodes['oslevel'] = node['nim']['clients'].values.collect { |m| m.fetch('oslevel', nil) }
      nodes['Cstate'] = node['nim']['clients'].values.collect { |m| m.fetch('lsnim', {}).fetch('Cstate', nil) }
      nodes['machine'].push('master')
      nodes['oslevel'].push(node['nim']['master']['oslevel'])
      print_hash_by_columns(nodes)
    end

    def clients_and_vios(node)
      check_nim_info(node)
      nodes = Hash.new { |h, k| h[k] = {} }
      nodes['machine'] = node['nim']['clients'].keys
      nodes['oslevel'] = node['nim']['clients'].values.collect { |m| m.fetch('oslevel', nil) }
      nodes['Cstate'] = node['nim']['clients'].values.collect { |m| m.fetch('lsnim', {}).fetch('Cstate', nil) }
      nodes['machine'].push(*node['nim']['vioses'].keys.flatten)
      nodes['oslevel'].push(*node['nim']['vioses'].values.collect { |m| m.fetch('oslevel', nil) }.flatten)
      nodes['Cstate'].push(*node['nim']['vioses'].values.collect { |m| m.fetch('lsnim', {}).fetch('Cstate', nil) }.flatten)
      nodes['machine'].push('master')
      nodes['oslevel'].push(node['nim']['master']['oslevel'])
      print_hash_by_columns(nodes)
    end

    def list_lpp_sources()
      check_nim_info(node)
      nodes = Hash.new { |h, k| h[k] = {} }
      nodes['lpp'] = node['nim']['lpp_sources'].keys
      print_hash_by_columns(nodes)
    end

    def vios(node)
      check_nim_info(node)
      nodes = Hash.new { |h, k| h[k] = {} }
      nodes['machine'] = node['nim']['vioses'].keys
      nodes['oslevel'] = node['nim']['vioses'].values.collect { |m| m.fetch('oslevel', nil) }
      nodes['Cstate'] = node['nim']['vioses'].values.collect { |m| m.fetch('lsnim', {}).fetch('Cstate', nil) }
      print_hash_by_columns(nodes)
    end

    def free_vios_disks(vios)
        disks = {}
        cmd_s = "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{vios} \"/usr/ios/cli/ioscli lspv -free\""

        Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
          stderr.each_line do |line|
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          unless wait_thr.value.success?
            stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
            msg = "Failed to get free Physical Volume list"
            log_warn("[#{vios}] #{msg}")
            raise ViosCmdError, "Error: #{msg} on #{vios}, command \"#{cmd_s}\" returns above error!"
          end

          # stdout is like:
          # NAME            PVID                                SIZE(megabytes)
          # hdiskX          none                                572325
          stdout.each_line do |line|
            next if line.start_with?('NAME') # skip header
            line.chomp!
            if line =~ /^(hdisk\S+)\s+(\S+)\s+([0-9]+)/
              pv_name = Regexp.last_match(1)
              disks[pv_name] = {}
              disks[pv_name]['pvid'] = Regexp.last_match(2)
              disks[pv_name]['size'] = Regexp.last_match(3)
            end
          end
        end
        nodes = Hash.new { |h, k| h[k] = {} }
        nodes['hdisk'] = disks.keys
        nodes['pvid'] = disks.values.collect { |m| m.fetch('pvid', nil) }
        nodes['size'] = disks.values.collect { |m| m.fetch('size', nil) }
        print_hash_by_columns(nodes)
    end

    def list_sps(filter_ml)
      # suma metadata
      tmp_dir = ::File.join(Chef::Config[:file_cache_path], 'metadata')
      suma = Suma.new('DisplayName' => '', 'RqType' => 'Latest', 'RqName' => nil, 'FilterML' => filter_ml, 'DLTarget' => tmp_dir)
      suma.metadata

      # find latest SP for highest TL
      list_of_sps = Dir.glob(::File.join(tmp_dir, 'installp', 'ppc', '*.install.tips.html'))
      list_of_sps.collect! do |file|
        file.gsub!('install.tips.html', 'xml')
        ::File.open(file) do |f|
          s = f.read
          #### BUG SUMA WORKAROUND ###
          s = s.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
          ########## END #############
          lvl = Regexp.last_match(1) if s.to_s =~ /^<SP name="([0-9]{4}-[0-9]{2}-[0-9]{2})/
          lvl = Regexp.last_match(1) if s.to_s =~ /^<SP name="([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})">$/
          lvl
        end
      end
      FileUtils.rm_rf(tmp_dir)
      list_of_sps
    end

    def levels(node, new = false)
      check_nim_info(node)
      levels = if new
                 { '7.1 TL0' => list_sps('7100-00'),
                   '7.1 TL1' => list_sps('7100-01'),
                   '7.1 TL2' => list_sps('7100-02'),
                   '7.1 TL3' => list_sps('7100-03'),
                   '7.1 TL4' => list_sps('7100-04'),
                   '7.2 TL0' => list_sps('7200-00'),
                   '7.2 TL1' => list_sps('7200-01') }
               else
                 { '7.1 TL0' => ['7100-00-00-0000', '7100-00-01-1037', '7100-00-02-1041', '7100-00-03-1115', '7100-00-04-1140', '7100-00-05-1207', '7100-00-06-1216', '7100-00-07-1228', '7100-00-08-1241', '7100-00-09-1316', '7100-00-10-1334'],
                   '7.1 TL1' => ['7100-01-00-0000', '7100-01-01-1141', '7100-01-02-1150', '7100-01-03-1207', '7100-01-04-1216', '7100-01-05-1228', '7100-01-06-1241', '7100-01-07-1316', '7100-01-08-1334', '7100-01-09-1341', '7100-01-10-1415'],
                   '7.1 TL2' => ['7100-02-00-0000', '7100-02-01-1245', '7100-02-02-1316', '7100-02-03-1334', '7100-02-04-1341', '7100-02-05-1415', '7100-02-06-1441', '7100-02-07-1524'],
                   '7.1 TL3' => ['7100-03-00-0000', '7100-03-01-1341', '7100-03-02-1412', '7100-03-03-1415', '7100-03-04-1441', '7100-03-05-1524', '7100-03-06-1543', '7100-03-07-1614', '7100-03-08-1642', '7100-03-09-1717'],
                   '7.1 TL4' => ['7100-04-00-0000', '7100-04-01-1543', '7100-04-02-1614', '7100-04-03-1643', '7100-04-04-1717'],
                   '7.2 TL0' => ['7200-00-00-0000', '7200-00-01-1543', '7200-00-02-1614', '7200-00-03-1642', '7200-00-04-1717'],
                   '7.2 TL1' => ['7200-01-00-0000', '7200-01-01-1643', '7200-01-02-1717'] }

               end
      levels.each do |k, v|
        levels[k] = v.collect do |oslevel|
          if node['nim']['lpp_sources'].keys.include?("#{oslevel}-lpp_source")
            oslevel + '*'
          else
            oslevel
          end
        end
      end
      print_hash_by_columns(levels)
    end

    def log_debug(message)
      Chef::Log.debug(message)
      # STDERR.puts('DEBUG: ' + message)
    end

    def log_info(message)
      Chef::Log.info(message)
      # STDOUT.puts('INFO: ' + message)
    end

    def log_warn(message)
      Chef::Log.warn(message)
      # STDOUT.puts("\033[0;31mWARN: " + message + "\033[0m")
    end

    # mainly used for Start/Stop info
    def put_info(message)
      Chef::Log.info(message)
      STDOUT.puts("INFO: " + message)
    end

    def put_warn(message)
      Chef::Log.warn(message)
      STDOUT.puts("\033[0;31mWARN: " + message + "\033[0m")
    end

    def put_error(message)
      Chef::Log.error(message)
      STDERR.puts("\033[0;31mERROR: " + message + "\033[0m")
    end


    #############################
    #     E X C E P T I O N     #
    #############################
    class NimInfoNotFound < StandardError
    end

    class InvalidLppSourceProperty < StandardError
    end

    class InvalidTargetsProperty < StandardError
    end

    class InvalidOsLevelProperty < StandardError
    end

    class InvalidLocationProperty < StandardError
    end

    class InvalidSumaProperties < StandardError
    end

    class SumaError < StandardError
    end

    class SumaPreviewError < SumaError
    end

    class SumaDownloadError < SumaError
    end

    class SumaMetadataError < SumaError
    end

    class NimError < StandardError
    end

    class NimCustError < NimError
    end

    class NimDefineError < NimError
    end

    class NimRemoveError < NimError
    end

    class NimHmcInfoError < StandardError
    end

    class NimLparInfoError < StandardError
    end

    class NimAltDiskInstallError < StandardError
    end

    class NimAltDiskInstallTimedOut < StandardError
    end

    class ViosCmdError < StandardError
    end

    class AltDiskFindError < StandardError
    end

    class AltDiskCleanError < StandardError
    end

    class SpLevel
      include Comparable
      attr_reader :aix
      attr_reader :rel
      attr_reader :tl
      attr_reader :sp

      def same_release?(other)
        @aix == other.aix && @rel == other.rel
      end

      def <=>(other)
        if @aix < other.aix
          -1
        elsif @aix > other.aix
          1
        elsif @rel < other.rel
          -1
        elsif @rel > other.rel
          1
        elsif @tl < other.tl
          -1
        elsif @tl > other.tl
          1
        elsif @sp < other.sp
          -1
        elsif @sp > other.sp
          1
        else
          0
        end
      end

      def to_s
        "#{@aix}.#{@rel}.#{format('%02d', @tl)}.#{format('%02d', @sp)}"
      end

      def initialize(aix, rel, tl, sp)
        @aix = aix.to_i
        @rel = rel.to_i
        @tl = tl.to_i
        @sp = sp.to_i
      end
    end

    class LppSource
      def self.exist?(lpp_source, niminfo)
        !niminfo['nim']['lpp_sources'].fetch(lpp_source, nil).nil?
      end
    end

    ###################
    #     S U M A     #
    ###################
    class Suma
      include AIX::PatchMgmt

      attr_reader :downloaded

      def initialize(fields, save_it = false)
        @display_name = fields['DisplayName']
        @rq_type = fields['RqType']
        @rq_name = fields['RqName']
        @filter_ml = fields['FilterML']
        @dl_target = fields['DLTarget']
        @save_it = save_it
        @suma_s = "/usr/sbin/suma -x -a DisplayName=\"#{@display_name}\" -a RqType=#{@rq_type} -a FilterML=#{@filter_ml} -a DLTarget=#{@dl_target}"
        #### BUG SUMA WORKAROUND ###
        @suma_s << " -a FilterDir=#{@dl_target}"
        ########## END #############
        @suma_s << " -a RqName=#{@rq_name}" if @rq_type != 'Latest'
        @suma_s << ' -w' if @save_it
        @dl = 0
        @downloaded = 0
        @failed = 0
        @skipped = 0
        ::FileUtils.mkdir_p(@dl_target) unless ::File.directory?(@dl_target)
        #### BUG SUMA WORKAROUND ###
        dir = ::File.join('usr', 'sys', 'inst.images')
        ::FileUtils.mkdir_p(dir) unless ::File.directory?(dir)
        ########## END #############
      end

      def failed?
        @failed.to_i > 0
      end

      def downloaded?
        @dl.to_f > 0 && @downloaded.to_i > 0
      end

      def duration(d)
        secs  = d.to_int
        mins  = secs / 60
        hours = mins / 60
        days  = hours / 24
        if days > 0
          "#{days} days and #{hours % 24} hours"
        elsif hours > 0
          "#{hours} hours and #{mins % 60} mins"
        elsif mins > 0
          "#{mins} mins #{secs % 60} secs"
        elsif secs >= 0
          "#{secs} secs"
        end
      end

      def metadata
        suma_s = @suma_s + ' -a Action=Metadata'
        log_debug("SUMA metadata operation: #{suma_s}")
        exit_status = Open3.popen3({ 'LANG' => 'C' }, suma_s) do |_stdin, stdout, stderr, wait_thr|
          stdout.each_line do |line|
            log_info("[STDOUT] #{line.chomp}")
          end
          stderr.each_line do |line|
            log_warn("Created task #{Regexp.last_match(1)}") if line =~ /Task ID ([0-9]+) created./
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          wait_thr.value # Process::Status object returned.
        end
        raise SumaMetadataError, "Error: Command \"#{suma_s}\" returns above error!" unless exit_status.success?
        log_info("Done suma metadata operation \"#{suma_s}\"")
      end

      def preview
        suma_s = @suma_s + ' -a Action=Preview'
        log_debug("SUMA preview operation: #{suma_s}")
        do_not_error = false
        exit_status = Open3.popen3({ 'LANG' => 'C' }, suma_s) do |_stdin, stdout, stderr, wait_thr|
          stdout.each_line do |line|
            @dl = Regexp.last_match(1).to_f / 1024 / 1024 / 1024 if line =~ /Total bytes of updates downloaded: ([0-9]+)/
            @downloaded = Regexp.last_match(1) if line =~ /([0-9]+) downloaded/
            @failed = Regexp.last_match(1) if line =~ /([0-9]+) failed/
            @skipped = Regexp.last_match(1) if line =~ /([0-9]+) skipped/
            log_info("[STDOUT] #{line.chomp}")
          end
          stderr.each_line do |line|
            do_not_error = true if line =~ /0500-035 No fixes match your query./
            log_warn("Created task #{Regexp.last_match(1)}") if line =~ /Task ID ([0-9]+) created./
            STDERR.puts line unless line =~ /(#{Regexp.quote('****************************************')}|Performing preview download.)/
            log_info("[STDERR] #{line.chomp}")
          end
          wait_thr.value # Process::Status object returned.
        end
        raise SumaPreviewError, "Error: Command \"#{suma_s}\" returns above error!" unless exit_status.success? || do_not_error
        log_warn("Preview: #{@downloaded} downloaded (#{@dl.to_f.round(2)} GB), #{@failed} failed, #{@skipped} skipped fixes") unless do_not_error
        log_info("Done suma preview operation \"#{suma_s}\"")
      end

      def download
        suma_s = @suma_s + ' -a Action=Download'
        log_debug("SUMA download operation: #{suma_s}")
        succeeded = 0
        failed = 0
        skipped = 0
        download_dl = 0
        download_downloaded = 0
        download_failed = 0
        download_skipped = 0
        puts "Start downloading #{@downloaded} fixes (~ #{@dl.to_f.round(2)} GB) to '#{@dl_target}' directory."
        exit_status = Open3.popen3({ 'LANG' => 'C' }, suma_s) do |_stdin, stdout, stderr, wait_thr|
          thr = Thread.new do
            start = Time.now
            loop do
              print "\033[2K\rSUCCEEDED: #{succeeded}/#{@downloaded}\tFAILED: #{failed}/#{@failed}\tSKIPPED: #{skipped}/#{@skipped}. (Total time: #{duration(Time.now - start)})."
              sleep 1
            end
          end
          stdout.each_line do |line|
            succeeded += 1 if line =~ /^Download SUCCEEDED:/
            failed += 1 if line =~ /^Download FAILED:/
            skipped += 1 if line =~ /^Download SKIPPED:/
            download_dl = Regexp.last_match(1).to_f / 1024 / 1024 / 1024 if line =~ /Total bytes of updates downloaded: ([0-9]+)/
            download_downloaded = Regexp.last_match(1) if line =~ /([0-9]+) downloaded/
            download_failed = Regexp.last_match(1) if line =~ /([0-9]+) failed/
            download_skipped = Regexp.last_match(1) if line =~ /([0-9]+) skipped/
            log_info("[STDOUT] #{line.chomp}")
          end
          stderr.each_line do |line|
            log_warn("Created task #{Regexp.last_match(1)}") if line =~ /Task ID ([0-9]+) created./
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          thr.exit
          wait_thr.value # Process::Status object returned.
        end
        puts "Finish downloading #{succeeded} fixes (~ #{download_dl.to_f.round(2)} GB)."
        log_info("Done suma download operation \"#{suma_s}\"")
        raise SumaDownloadError, "Error: Command \"#{suma_s}\" returns above error!" unless exit_status.success?
        @dl = download_dl
        @downloaded = download_downloaded
        @failed = download_failed
        @skipped = download_skipped
      end
    end  # Suma

    #################
    #     N I M     #
    #################
    class Nim
      include AIX::PatchMgmt

      def exist?(resource)
        !shell_out("lsnim | grep #{resource}").error?
      end

      def define_lpp_source(lpp_source, dl_target, comments = 'build by chef recipe')
        nim_s = "/usr/sbin/nim -o define -t lpp_source -a server=master -a location=#{dl_target} -a packages=all -a comments='#{comments}' #{lpp_source}"
        log_debug("NIM define operation: #{nim_s}")
        exit_status = Open3.popen3({ 'LANG' => 'C' }, nim_s) do |_stdin, stdout, stderr, wait_thr|
          stdout.each_line do |line|
            log_info("[STDOUT] #{line.chomp}")
          end
          stderr.each_line do |line|
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          wait_thr.value # Process::Status object returned.
        end
        raise NimDefineError, "Error: Command \"#{nim_s}\" returns above error!" unless exit_status.success?
        log_info("Done nim define operation \"#{nim_s}\"")
      end

      def remove_resource(resource)
        nim_s = "/usr/sbin/nim -o remove #{resource}"
        log_debug("NIM remove operation: #{nim_s}")
        exit_status = Open3.popen3({ 'LANG' => 'C' }, nim_s) do |_stdin, stdout, stderr, wait_thr|
          stdout.each_line do |line|
            log_info("[STDOUT] #{line.chomp}")
          end
          stderr.each_line do |line|
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          wait_thr.value # Process::Status object returned.
        end
        raise NimRemoveError, "Error: Command \"#{nim_s}\" returns above error!" unless exit_status.success?
        log_info("Done nim remove operation \"#{nim_s}\"")
      end

      def perform_async_customization(lpp_source, clients)
        nim_s = "/usr/sbin/nim -o cust -a lpp_source=#{lpp_source} -a fixes=update_all -a accept_licenses=yes -a async=yes #{clients}"
        log_debug("NIM asynchronus cust operation: #{nim_s}")
        puts "\nStart updating machine(s) '#{clients}' to #{lpp_source}."
        do_not_error = false
        exit_status = Open3.popen3({ 'LANG' => 'C' }, nim_s) do |_stdin, stdout, stderr, wait_thr|
          stdout.each_line do |line|
            do_not_error = true if line =~ /Either the software is already at the same level as on the media, or/
            log_info("[STDOUT] #{line.chomp}")
          end
          stderr.each_line do |line|
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          wait_thr.value # Process::Status object returned.
        end
        puts "Finish updating #{clients} asynchronously."
        raise NimCustError, "Error: Command \"#{nim_s}\" returns above error!" unless exit_status.success? || do_not_error
        log_info("Done NIM customize operation \"#{nim_s}\"")
      end

      def perform_sync_customization(lpp_source, clients)
        nim_s = "/usr/sbin/nim -o cust -a lpp_source=#{lpp_source} -a fixes=update_all -a accept_licenses=yes -a async=no #{clients}"
        log_debug("NIM synchronous cust operation: #{nim_s}")
        puts "Start updating machine(s) '#{clients}' to #{lpp_source}."
        do_not_error = false
        exit_status = Open3.popen3({ 'LANG' => 'C' }, nim_s) do |_stdin, stdout, stderr, wait_thr|
          stdout.each_line do |line|
            print "\033[2K\r#{line.chomp}" if line =~ /^Filesets processed:.*?[0-9]+ of [0-9]+/
            print "\033[2K\r#{line.chomp}" if line =~ /^Finished processing all filesets./
            log_info("[STDOUT] #{line.chomp}")
          end
          stderr.each_line do |line|
            do_not_error = true if line =~ /Either the software is already at the same level as on the media, or/
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          wait_thr.value # Process::Status object returned.
        end
        puts "Finish updating #{clients} synchronously."
        raise NimCustError, "Error: Command \"#{nim_s}\" returns above error!" unless exit_status.success? || do_not_error
        log_info("Done nim customize operation \"#{nim_s}\"")
      end

      def perform_efix_customization(lpp_source, client, filesets = 'all')
        nim_s = "/usr/sbin/nim -o cust -a lpp_source=#{lpp_source} -a filesets='#{filesets}' #{client}"
        log_debug("NIM install efixes cust operation: #{nim_s}")
        puts "Start patching machine(s) '#{client}'."
        exit_status = Open3.popen3({ 'LANG' => 'C' }, nim_s) do |_stdin, stdout, stderr, wait_thr|
          thr = Thread.new do
            loop do
              print '.'
              sleep 3
            end
          end
          stdout.each_line do |line|
            line.chomp!
            print "\033[2K\r#{line}" if line =~ /^Processing Efix Package [0-9]+ of [0-9]+.$/
            puts "\n#{line}" if line =~ /^EPKG NUMBER/
            puts line if line =~ /^===========/
            puts "\033[0;31m#{line}\033[0m" if line =~ /INSTALL.*?FAILURE/
            puts "\033[0;32m#{line}\033[0m" if line =~ /INSTALL.*?SUCCESS/
            log_info("[STDOUT] #{line}")
          end
          stderr.each_line do |line|
            line.chomp!
            STDERR.puts line
            log_info("[STDERR] #{line}")
          end
          thr.exit
          wait_thr.value # Process::Status object returned.
        end
        puts "Finish patching #{client}."
        raise NimCustError, "Error: Command \"#{nim_s}\" returns above error!" unless exit_status.success?
      end

      def perform_efix_vios_customization(lpp_source, vios, _filesets = 'all')
        nim_s = "/usr/sbin/nim -o updateios -a preview=no -a lpp_source=#{lpp_source} #{vios}"
        log_debug("NIM updateios operation: #{nim_s}")
        puts "Start patching machine(s) '#{vios}'."
        exit_status = Open3.popen3({ 'LANG' => 'C' }, nim_s) do |_stdin, stdout, stderr, wait_thr|
          thr = Thread.new do
            loop do
              print '.'
              sleep 3
            end
          end
          stdout.each_line do |line|
            line.chomp!
            print "\033[2K\r#{line}" if line =~ /^Processing Efix Package [0-9]+ of [0-9]+.$/
            puts "\n#{line}" if line =~ /^EPKG NUMBER/
            puts line if line =~ /^===========/
            puts "\033[0;31m#{line}\033[0m" if line =~ /INSTALL.*?FAILURE/
            puts "\033[0;32m#{line}\033[0m" if line =~ /INSTALL.*?SUCCESS/
            log_info("[STDOUT] #{line}")
          end
          stderr.each_line do |line|
            line.chomp!
            STDERR.puts line
            log_info("[STDERR] #{line}")
          end
          thr.exit
          wait_thr.value # Process::Status object returned.
        end
        puts "Finish patching #{vios}."
        raise NimCustError, "Error: Command \"#{nim_s}\" returns above error!" unless exit_status.success?
      end

      # -----------------------------------------------------------------
      # Get the hmc info on the nim master
      #
      #    return a dic with hmc info
      #    raise NimHmcInfoError in case of error
      # -----------------------------------------------------------------
      def get_hmc_info()
        info_hash = {}
        obj_key = ''
        cmd_s = "/usr/sbin/lsnim -t hmc -l"
        log_debug("get_hmc_info: #{cmd_s}")
        exit_status = Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
          stderr.each_line do |line|
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          unless wait_thr.value.success?
            stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
            raise NimHmcInfoError, "Error: Command \"#{cmd_s}\" returns above error!"
          end

          stdout.each_line do |line|
            log_info("[STDOUT] #{line.chomp}")
            # HMC name
            if line =~ /^(\S+):/
              obj_key = Regexp.last_match(1)
              info_hash[obj_key] = {}
              next
            end
            # Cstate
            if line =~ /^\s+Cstate\s+=\s+(.*)$/
                cstate = Regexp.last_match(1)
                info_hash[obj_key]['cstate'] = cstate
                next
            end
            # passwd_file
            if line =~ /^\s+passwd_file\s+=\s+(.*)$/
                passwd_file = Regexp.last_match(1)
                info_hash[obj_key]['passwd_file'] = passwd_file
                next
            end
            # login
            if line =~ /^\s+login\s+=\s+(.*)$/
                login = Regexp.last_match(1)
                info_hash[obj_key]['login'] = login
                next
            end
            # ip
            if line =~ /^\s+if1\s*=\s*\S+\s*(\S*)\s*.*$/
                ip = Regexp.last_match(1)
                info_hash[obj_key]['ip'] = ip
                next
            end
          end
        end

        log_info("HMC information:")
        info_hash.keys.each do |obj_key|
            log_info("#{obj_key}")
            info_hash[obj_key].keys.each do |k|
                log_info("  #{k}: #{info_hash[obj_key][k]}")
            end
        end
        info_hash
      end

      # -----------------------------------------------------------------
      # Get the list of the lpar (standalones or vios) defined on the nim
      #   master, and get their cstate.
      #
      #    return a dic with lpar info
      #    raise NimLparInfoError in case of error
      # -----------------------------------------------------------------
      def get_nim_clients_info(lpar_type)
        info_hash = {}
        obj_key = ''
        cmd_s = "/usr/sbin/lsnim -t #{lpar_type} -l"
        log_debug("get_nim_clients_info: '#{cmd_s}'")
        Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
          stderr.each_line do |line|
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          unless wait_thr.value.success?
            stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
            raise NimLparInfoError, "Error: Command \"#{cmd_s}\" returns above error!"
          end

          stdout.each_line do |line|
            log_info("[STDOUT] #{line.chomp}")
            # lpar object name
            if line =~ /^(\S+):/
              obj_key = Regexp.last_match(1)
              info_hash[obj_key] = {}
              next
            end
            # Cstate
            if line =~ /^\s+Cstate\s+=\s+(.*)$/
              cstate = Regexp.last_match(1)
              info_hash[obj_key]['cstate'] = cstate
              next
            end

            # For VIOS store the management profile
            if lpar_type == 'vios'
              if line =~ /^\s+mgmt_profile1\s+=\s+(.*)$/
                match_mgmtprof = Regexp.last_match(1)
                mgmt_elts = match_mgmtprof.split
                if mgmt_elts.size == 3
                  info_hash[obj_key]['mgmt_hmc_id'] = mgmt_elts[0]
                  info_hash[obj_key]['mgmt_vios_id'] = mgmt_elts[1]
                  info_hash[obj_key]['mgmt_cec_serial'] = mgmt_elts[2]
                end
              end
              if line =~ /^\s+if1\s+=\s+\S+\s+(\S+)\s+.*$/
                info_hash[obj_key]['vios_ip'] = Regexp.last_match(1)
              end
            end
          end
        end

        log_info("NIM Clients for type: '#{lpar_type}'")
        info_hash.keys.each do |obj_key|
            log_info("#{obj_key}")
            info_hash[obj_key].keys.each do |k|
                log_info("  #{k}: #{info_hash[obj_key][k]}")
            end
        end
        info_hash
      end

      # -----------------------------------------------------------------
      # Run the NIM alt_disk_install command to launch
      # the alternate copy operation on specified vios
      #
      #    raise NimAltDiskInstallError in case of error
      # -----------------------------------------------------------------
      def perform_altdisk_install(vios, source, disk, set_bootlist='no', boot_client='no')
        cmd_s = "/usr/sbin/nim -o alt_disk_install -a source=rootvg -a disk=#{disk} -a set_bootlist=#{set_bootlist} -a boot_client=#{boot_client} #{vios}"
        log_info("perform_altdisk_install: '#{cmd_s}'")
        # TBC - For testing, you can uncomment to bypass alt_disk_install operation
        # cmd_s = "/usr/sbin/lsnim -Z -a Cstate -a info -a Cstate_result #{vios}"
        # log_info("perform_altdisk_install: overwrite with cmd_s:'#{cmd_s}'")
        exit_status = Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
          stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
          stderr.each_line do |line|
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          wait_thr.value # Process::Status object returned.
        end

        raise NimAltDiskInstallError, "Command \"#{cmd_s}\" returns above error!" unless exit_status.success?
      end

      # -----------------------------------------------------------------
      # Wait for the alternate disk copy operation to finish
      #
      # when alt_disk_install operation ends the NIM object state changes
      # from "a client is being prepared for alt_disk_install" or
      #      "alt_disk_install operation is being performed"
      # to   "ready for NIM operation"
      #
      # You migh want a timeout of 30 minutes (count=180, sleep=10s), if
      # there is no progress in NIM operation "info" attribute for this
      # duration, it can be considered as an error.
      #
      #    Return
      #    0   if the alt_disk_install operation ends with success
      #    1   if the alt_disk_install operation failed
      #    -1  if the alt_disk_install operation timed out
      #
      #    raise NimLparInfoError if cannot get NIM state
      # -----------------------------------------------------------------
      def wait_alt_disk_install(vios, check_count=180, sleep_time=10)
        nim_info_prev = "___"   # this info should not appears in nim info attribute
        nim_info = ""
        count = 0
        wait_time = 0
        cmd_s = "/usr/sbin/lsnim -Z -a Cstate -a info -a Cstate_result #{vios}"
        log_info("wait_alt_disk_install: '#{cmd_s}'")

        while count <= check_count do
          sleep(sleep_time)
          wait_time += 10
          nim_Cstate = ""
          nim_result = ""
          nim_info = ""

          Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
            stderr.each_line do |line|
              STDERR.puts line
              log_info("[STDERR] #{line.chomp}")
            end
            unless wait_thr.value.success?
              stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
              raise NimLparInfoError, "Failed to get the NIM state for vios '#{vios}', see above error!"
            end

            stdout.each_line do |line|
              log_debug("[STDOUT] #{line.chomp}")

              # info attribute (that appears in 3rd possition) can be empty. So stdout looks like:
              # #name:Cstate:info:Cstate_result:
              # <viosName>:ready for a NIM operation:success:  -> len=3
              # <viosName>:alt_disk_install operation is being performed:Creating logical volume alt_hd2.:success:  -> len=4
              # <viosName>:ready for a NIM operation:0505-126 alt_disk_install- target disk hdisk2 has a volume group assigned to it.:failure:  -> len=4
              nim_status = line.strip.split(':')
              if nim_status[0] != "#name"
                  print("\033[2K\r#{nim_status[2]}")
                  log_info("nim_status:#{nim_status}")
              else
                  next
              end

              nim_Cstate = nim_status[1]
              if nim_status.length == 3 && (nim_status[2].downcase == "success" || nim_status[2].downcase == "failure")
                nim_result = nim_status[2].downcase
              elsif nim_status.length > 3
                nim_info = nim_status[2]
                nim_result = nim_status[3].downcase
              else
                log_warn("[#{vios}] Unexpected output #{nim_status} for command '#{cmd_s}'")
              end

              if nim_Cstate.downcase == "ready for a nim operation"
                log_info("NIM alt_disk_install operation on #{vios} ended with #{nim_result}")
                unless nim_result == "success"
                  msg = "Failed to perform NIM alt_disk_install operation on #{vios}: #{nim_info}"
                  put_error(msg)
                  return 1
                end
                print("\033[2K\r")
                return 0    # here the operation succeeded
              else
                if nim_info_prev == nim_info
                  count += 1
                else
                  nim_info_prev = nim_info unless nim_info.empty?
                  count = 0
                end
              end
              if wait_time.modulo(60) == 0
                msg = "Waiting the NIM alt disk copy on #{vios}... duration: #{wait_time / 60} minute(s)"
                print("\033[2K\r#{msg}")
                log_info(msg)
              end
            end
          end
        end    # while count

        # timed out before the end of alt_disk_install
        msg = "NIM alt_disk_install operation for #{vios} shows no progress in #{count * sleep_time / 60} minute(s): #{nim_info}"
        put_error(msg)
        return -1
      end

    end  # Nim

    #################
    #   VioServer   #
    #################
    class VioServer
      include AIX::PatchMgmt

      # -----------------------------------------------------------------
      # Get the list of PVs using 'lspv' command on a vios
      # and build a hash in nim_vios[vios]['pvs'][pv_name]
      # with PV info.
      # It uses c_rsh to connect the vios and ioscli to run the command.
      #
      #    Raise ViosCmdError in case of error
      # -----------------------------------------------------------------
      def get_pvs(nim_vios, vios)
        nim_vios[vios]['pvs'] = {}
        cmd_s = "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{nim_vios[vios]['vios_ip']} \"/usr/ios/cli/ioscli lspv\""

        log_debug("get_pvs: '#{cmd_s}'")
        Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
          stderr.each_line do |line|
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          unless wait_thr.value.success?
            stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
            msg = "Failed to get Physical Volume list on #{vios}, command \"#{cmd_s}\" returns above error!"
            raise ViosCmdError, msg
          end

          # stdout is like:
          # NAME             PVID                                 VG               STATUS
          # hdisk0           000018fa3b12f5cb                     rootvg           active
          stdout.each_line do |line|
            log_debug("[STDOUT] #{line.chomp}")

            next if line.start_with?('NAME') # skip header
            line.chomp!
            if line =~ /^(hdisk\S+)\s+(\S+)\s+(\S+)\s*(\S*)/
              pv_name = Regexp.last_match(1)
              nim_vios[vios]['pvs'][pv_name] = {}
              nim_vios[vios]['pvs'][pv_name]['pvid'] = Regexp.last_match(2)
              nim_vios[vios]['pvs'][pv_name]['vg'] = Regexp.last_match(3)
              nim_vios[vios]['pvs'][pv_name]['status'] = Regexp.last_match(4)
            end
          end
        end

        log_info('List of PVs:')
        nim_vios[vios]['pvs'].keys.each do |k|
          log_info("  #{vios}['pvs'][#{k}] = #{nim_vios[vios]['pvs'][k]}")
        end
      end

      # -----------------------------------------------------------------
      # Get the list of free PVs using 'lspv -free' command on a vios
      # and build a hash in nim_vios[vios]['free_pvs'][pv_name]
      # with PV info.
      # It uses c_rsh to connect the vios and ioscli to run the command.
      #
      #    Raise ViosCmdError in case of error
      # -----------------------------------------------------------------
      def get_free_pvs(nim_vios, vios)
        nim_vios[vios]['free_pvs'] = {}
        cmd_s = "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{nim_vios[vios]['vios_ip']} \"/usr/ios/cli/ioscli lspv -free\""

        log_debug("get_free_pvs: '#{cmd_s}'")
        Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
          stderr.each_line do |line|
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          unless wait_thr.value.success?
            stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
            msg = "Failed to get free Physical Volume list on #{vios}, command \"#{cmd_s}\" returns above error!"
            raise ViosCmdError, msg
          end

          # stdout is like:
          # NAME            PVID                                SIZE(megabytes)
          # hdiskX          none                                572325
          stdout.each_line do |line|
            log_debug("[STDOUT] #{line.chomp}")

            next if line.start_with?('NAME') # skip header
            line.chomp!
            if line =~ /^(hdisk\S+)\s+(\S+)\s+([0-9]+)/
              pv_name = Regexp.last_match(1)
              nim_vios[vios]['free_pvs'][pv_name] = {}
              nim_vios[vios]['free_pvs'][pv_name]['pvid'] = Regexp.last_match(2)
              nim_vios[vios]['free_pvs'][pv_name]['size'] = Regexp.last_match(3).to_i
              log_debug("got free PV #{pv_name} of #{nim_vios[vios]['free_pvs'][pv_name]['size']} MB with PVID: #{nim_vios[vios]['free_pvs'][pv_name]['pvid']}")
            end
          end
        end

        log_info('List of free PVs:')
        nim_vios[vios]['free_pvs'].keys.each do |k|
          log_info("  #{vios}['free_pvs'][#{k}] = #{nim_vios[vios]['free_pvs'][k]}")
        end
      end

      # -----------------------------------------------------------------
      # Return the total and used vg sizes in megabytes
      #
      #    Raise ViosCmdError in case of error
      # -----------------------------------------------------------------
      def get_vg_size(nim_vios, vios, vg_name)
        vg_size = 0
        used_size = 0
        cmd_s = "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{nim_vios[vios]['vios_ip']} \"/usr/ios/cli/ioscli lsvg #{vg_name}\""

        log_info("get_vg_size: '#{cmd_s}'")
        Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
          stderr.each_line do |line|
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          unless wait_thr.value.success?
            stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
            msg = "Failed to get Volume Group '#{vg_name}' size on #{vios}, command \"#{cmd_s}\" returns above error!"
            raise ViosCmdError, msg
          end

          # stdout is like:
          # parse lsvg outpout to get the size in megabytes:
          # VG STATE:           active                   PP SIZE:        512 megabyte(s)
          # VG PERMISSION:      read/write               TOTAL PPs:      558 (285696 megabytes)
          # MAX LVs:            256                      FREE PPs:       495 (253440 megabytes)
          # LVs:                14                       USED PPs:       63 (32256 megabytes)
          stdout.each_line do |line|
            log_debug("[STDOUT] #{line.chomp}")
            line.chomp!
            if line =~ /.*TOTAL PPs:\s+\d+\s+\((\d+)\s+megabytes\).*/
              vg_size = Regexp.last_match(1).to_i
            elsif line =~ /.*USED PPs:\s+\d+\s+\((\d+)\s+megabytes\).*/
              used_size += Regexp.last_match(1).to_i
            elsif line =~ /.*PP SIZE:\s+(\d+)\s+megabyte\(s\).*/
              used_size += Regexp.last_match(1).to_i
            end
          end
        end

        if vg_size == 0 || used_size == 0
            msg = "Failed to get Volume Group '#{vg_name}' size: TOTAL PPs=#{vg_size}, USED PPs+1=#{vg_size[1]} on #{vios}"
            raise ViosCmdError, msg
          end

        log_info("VG '#{vg_name}' TOTAL PPs=#{vg_size} MB, USED PPs+1=#{used_size} MB")
        [vg_size, used_size]
      end

      # -----------------------------------------------------------------
      # Find a valid alternate disk that
      # - exists,
      # - is not part of a VG
      # - as enough space to copy the rootvg
      # and so can be used for the alternate disk copy.
      #
      # Fill altdisk_hash[vios] with the selected hdisk
      #
      # sets the targets_status acordingly:
      #  targets_status[vios_key] = "FAILURE-ALTDC <error message>"
      #  targets_status[vios_key] = "SUCCESS-ALTDC"
      #
      #    Return 0 if alternat disk is found
      #           1 otherwise
      #
      #    Raise AltDiskFindError in case of error
      # -----------------------------------------------------------------
      def find_valid_altdisk(nim_vios, vios_list, vios_key, targets_status, altdisk_hash, disk_size_policy)
        rootvg_size = 0
        used_size = 0
        used_pv = []
        vios_list.each do |vios|

          err_label = "FAILURE-ALTDC1"

          # get pv list
          begin
            get_pvs(nim_vios, vios)
          rescue ViosCmdError => e
            msg = "Failed to find a valid alternate disk on #{vios}: #{e.message}"
            raise AltDiskFindError, msg
          end

          # check an alternate disk not already exists
          nim_vios[vios]['pvs'].each do |pv_name, pv|
            if pv['vg'] == "altinst_rootvg"
              targets_status[vios_key] = "#{err_label} an alternate disk (#{pv_name}) already exists on #{vios}"
              put_error("An alternate rootvg already exists on disk #{pv_name} on #{vios}")
              return 1
            end
          end

          begin
            rootvg_size, used_size = get_vg_size(nim_vios, vios, "rootvg")
          rescue ViosCmdError => e
            msg = "Failed to find a valid alternate disk on #{vios}: #{e.message}"
            raise AltDiskFindError, msg
          end

          begin
            get_free_pvs(nim_vios, vios)
          rescue ViosCmdError => e
            msg = "Failed to find a valid alternate disk on #{vios}: #{e.message}"
            raise AltDiskFindError, msg
          end

          if nim_vios[vios]['free_pvs'] == {}
            targets_status[vios_key] = "#{err_label} no disk available on #{vios}"
            put_error("No disk available on #{vios}")
            return 1
          end
          free_pvs = nim_vios[vios]['free_pvs']

          # in auto mode, find the first alternate disk available
          if altdisk_hash[vios] == ""
            prev_disk = ""
            diffsize = 0
            prev_diffsize = 0
            # parse free disks in increasing size order
            free_pvs.each_key.sort_by { |k| free_pvs[k]['size'] }.each do |hdisk|
              # disk to small or already used
              if free_pvs[hdisk]['size'] < used_size or
                used_pv.include?(free_pvs[hdisk]['pvid'])
                next
              end

              # smallest disk that can be selected
              if disk_size_policy == 'minimize'
                altdisk_hash[vios] = hdisk
                if free_pvs[hdisk]['pvid'] != "none"
                  used_pv << free_pvs[hdisk]['pvid']
                end
                break
              end

              diffsize = free_pvs[hdisk]['size'] - rootvg_size
              # matching disk size
              if diffsize == 0
                altdisk_hash[vios] = hdisk
                if free_pvs[hdisk]['pvid'] != "none"
                  used_pv << free_pvs[hdisk]['pvid']
                end
                break
              end

              if diffsize > 0
                # diffsize > 0: first disk found bigger than the rootvg disk
                selected_disk = ""
                if disk_size_policy == 'upper'
                  selected_disk = hdisk
                elsif disk_size_policy == 'lower'
                  if prev_disk == ""
                    # Best Can Do...
                    selected_disk = hdisk
                  else
                    selected_disk = prev_disk
                  end
                else
                  # disk_size_policy == 'nearest'
                  if prev_disk == ""
                    selected_disk = hdisk
                  elsif prev_diffsize.abs > diffsize
                    selected_disk = hdisk
                  else
                    selected_disk = prev_disk
                  end
                end

                altdisk_hash[vios] = selected_disk
                if free_pvs[selected_disk]['pvid'] != "none"
                  used_pv << free_pvs[selected_disk]['pvid']
                end
                break
              else
                # disk size less than rootvg disk size
                #   but big enough to contain the used PPs
                prev_disk = hdisk
                prev_diffsize = diffsize
                next
              end
            end

            if altdisk_hash[vios] == ""
              if prev_disk != ""
                # Best Can Do...
                altdisk_hash[vios] = prev_disk
                if free_pvs[prev_disk]['pvid'] != "none"
                  used_pv << free_pvs[prev_disk]['pvid']
                end
              else
                targets_status[vios_key] = "#{err_label} to find an alternate disk on #{vios}"
                put_error("No available disk with size greater than #{used_size} MB found on #{vios}")
                return 1
              end
            end

          # hdisk specified by the user
          else
            # check the specified hdisk is large enough
            hdisk = altdisk_hash[vios]
            if nim_vios[vios]['free_pvs'].has_key?(hdisk)
              if used_pv.include?(nim_vios[vios]['free_pvs'][hdisk]['pvid'])
                targets_status[vios_key] = "#{err_label} alternate disk #{hdisk} already used on the mirror VIOS"
                put_error("Alternate disk #{hdisk} already used on the mirror VIOS")
                return 1
              end
              if nim_vios[vios]['free_pvs'][hdisk]['size'] >= rootvg_size
                if free_pvs[hdisk]['pvid'] != "none"
                  used_pv << free_pvs[hdisk]['pvid']
                end
              else
                if nim_vios[vios]['free_pvs'][hdisk]['size'] >= used_size
                  if free_pvs[hdisk]['pvid'] != "none"
                    used_pv << free_pvs[hdisk]['pvid']
                  end
                  put_warn("Alternate disk #{hdisk} is smaller than the current rootvg")
                else
                  targets_status[vios_key] = "#{err_label} alternate disk #{hdisk} is too small on #{vios}"
                  put_error("Alternate disk #{hdisk} is too small on #{vios}")
                  return 1
                end
              end
            else
              targets_status[vios_key] = "#{err_label} disk #{hdisk} is not available on #{vios}"
              put_error("Alternate disk #{hdisk} is either not found or not available on #{vios}")
              return 1
            end
          end
        end

        # Disks found
        return 0
      end

      # -----------------------------------------------------------------
      # Find the existing altinst rootvg on vios
      #
      # Fill altdisk_hash[vios] with the corresponding hdisk
      #
      #    Return 0 for success
      #
      #    Raise AltDiskFindError in case of error
      # -----------------------------------------------------------------
      def get_altinst_rootvg_disk(nim_vios, vios, altdisk_hash)
        ret = 0

        begin
          get_pvs(nim_vios, vios)
        rescue ViosCmdError => e
          msg = "Failed to find the alternate install rootvg on #{vios}: #{e.message}"
          raise AltDiskFindError, msg
        end

        # in auto mode, search for altinst_rootvg
        if altdisk_hash.empty? || !altdisk_hash.has_key?(vios)
            altdisk_hash[vios] = ""
        end
        if altdisk_hash[vios].empty?
          nim_vios[vios]['pvs'].keys.each do |hdisk|
            if nim_vios[vios]['pvs'][hdisk]['vg'] == "altinst_rootvg"
              if altdisk_hash[vios].empty?
                altdisk_hash[vios] = hdisk
              else
                msg = "There are several alternate install rootvg on #{vios}: #{altdisk_hash[vios]} and #{hdisk}"
                altdisk_hash[vios] = ""
                raise AltDiskFindError, msg
              end
            end
          end
        end

        # Check we found an disk and its vg name is altinst_rootvg
        if altdisk_hash[vios].empty?
          msg = "No alternate install rootvg found on #{vios}"
          ret = 1
        elsif !nim_vios[vios]['pvs'].has_key?(altdisk_hash[vios])
          msg = "No disk '#{altdisk_hash[vios]}' found on #{vios}"
          ret = 1
        elsif nim_vios[vios]['pvs'][altdisk_hash[vios]]['vg'] != "altinst_rootvg"
          msg = "Disk '#{altdisk_hash[vios]}' is not an alternate install rootvg on #{vios}"
          ret = 1
        end
        unless ret == 0
          altdisk_hash[vios] = ""
          put_warn(msg)
          return ret
        end

        log_info("Found altinst_rootvg on disk '#{altdisk_hash[vios]}'")
        return ret
      end

      # -----------------------------------------------------------------
      # Remove the altinst_rootvg with the alt_rootvg_op command
      #
      #    Return 0 for success
      #    Raise AltDiskFindError in case of error
      # -----------------------------------------------------------------
      def altdisk_copy_cleanup(nim_vios, vios, altdisk_hash)
        ret = 0

        put_info("Start removing altinst_rootvg from '#{altdisk_hash[vios]}' on '#{vios}'.")
        cmd_s = "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{nim_vios[vios]['vios_ip']} \"/usr/sbin/alt_rootvg_op -X altinst_rootvg\""
        log_info("altdisk_copy_cleanup: '#{cmd_s}'")
        exit_status = Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
          stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
          stderr.each_line do |line|
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          wait_thr.value # Process::Status object returned.
        end
        put_info("Finish removing altinst_rootvg from '#{altdisk_hash[vios]}' on '#{vios}'.")
        unless exit_status.success?
          msg = "Failed to remove altinst_rootvg on #{vios}, see above error!"
          raise AltDiskCleanError, msg
        end

        put_info("Clean the LVM info on #{altdisk_hash[vios]}.")
        cmd_s = "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{nim_vios[vios]['vios_ip']} \"/usr/bin/dd if=/dev/zero of=/dev/#{altdisk_hash[vios]}  seek=7 count=1 bs=512\""
        log_info("altdisk_copy_cleanup: '#{cmd_s}'")
        exit_status = Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
          stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
          stderr.each_line do |line|
            STDERR.puts line
            log_info("[STDERR] #{line.chomp}")
          end
          wait_thr.value # Process::Status object returned.
        end
        put_info("Finish cleaning the LVM info from '#{altdisk_hash[vios]}' on '#{vios}'.")
        unless exit_status.success?
          msg = "Failed to clean the LVM info from '#{altdisk_hash[vios]}' on #{vios}, see above error!"
          raise AltDiskCleanError, msg
        end

        ret
      end

    end  # VioServer


    # -----------------------------------------------------------------
    # Print hash in column format
    #
    #    +---------+-----------------+---------------------------+
    #    | machine |     oslevel     |          Cstate           |
    #    +---------+-----------------+---------------------------+
    #    | client1 | 7100-01-04-1216 | ready for a NIM operation |
    #    | client2 | 7100-03-01-1341 | ready for a NIM operation |
    #    | client3 | 7100-04-00-0000 | ready for a NIM operation |
    #    | master  | 7200-01-00-0000 |                           |
    #    +---------+-----------------+---------------------------+
    #
    # -----------------------------------------------------------------
    def print_hash_by_columns(data)
      widths = {}
      data.keys.each do |key|
        widths[key] = 5 # minimum column width
        # longest string len of values
        val_len = data[key].max_by { |v| v.to_s.length }.to_s.length
        widths[key] = val_len > widths[key] ? val_len : widths[key]
        # length of key
        widths[key] = key.to_s.length > widths[key] ? key.to_s.length : widths[key]
      end

      result = '+'
      data.keys.each { |key| result += ''.center(widths[key] + 2, '-') + '+' }
      result += "\n"
      result += '|'
      data.keys.each { |key| result += key.to_s.center(widths[key] + 2) + '|' }
      result += "\n"
      result += '+'
      data.keys.each { |key| result += ''.center(widths[key] + 2, '-') + '+' }
      result += "\n"
      length = data.values.max_by(&:length).length
      0.upto(length - 1).each do |i|
        result += '|'
        data.keys.each { |key| result += data[key][i].to_s.center(widths[key] + 2) + '|' }
        result += "\n"
      end
      result += '+'
      data.keys.each { |key| result += ''.center(widths[key] + 2, '-') + '+' }
      result += "\n"
      result
    end

    # -----------------------------------------------------------------
    # Check NIM hash info is well configured
    #
    #    raise NimInfoNotFound in case of error
    # -----------------------------------------------------------------
    def check_nim_info(hash)
      master = hash.fetch('nim', {}).fetch('master').fetch('oslevel')
      log_debug("master oslevel is #{master}")

      all_machines = hash.fetch('nim', {}).fetch('clients').keys
      log_debug("client machine's list is #{all_machines}")

      all_lpp_sources = hash.fetch('nim', {}).fetch('lpp_sources').keys
      log_debug("lpp source's list is #{all_lpp_sources}")
    rescue KeyError
      raise NimInfoNotFound, 'Error: cannot find NIM information'
    end

    # -----------------------------------------------------------------
    # Expand the target machine list parameter
    #
    #    "*" should be specified as target to apply an operation on all
    #        the machines
    #    If target parameter is empty or not present operation is
    #        performed locally
    #
    #    raise InvalidTargetsProperty in case of error
    #    - cannot contact the target machines
    # -----------------------------------------------------------------
    def expand_targets(targets, clients)
      return [] if targets.nil? || targets.empty?

      selected_machines = []
      targets.split(/[,\s]/).each do |machine|
        selected_machines.push(machine) if machine == 'master'
        # expand wildcard
        machine.gsub!(/\*/, '.*?')
        clients.each do |m|
          selected_machines.concat(m.split) if m =~ /^#{machine}$/
        end
      end
      raise InvalidTargetsProperty, "The target patern '#{targets}' does not match any NIM client." if selected_machines.empty?
      selected_machines = selected_machines.uniq
      log_info("List of targets expanded to #{selected_machines}")
      selected_machines
    end

    # -----------------------------------------------------------------
    # List fixes with emgr
    #
    #    raise EmgrListError in case of error
    # -----------------------------------------------------------------
    def list_fixes(machine)
      array_fixes = []
      emgr_s = "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{machine} \"/usr/sbin/emgr -l\""
      log_debug("EMGR list: #{emgr_s}")
      exit_status = Open3.popen3({ 'LANG' => 'C' }, emgr_s) do |_stdin, stdout, stderr, wait_thr|
        stdout.each_line do |line|
          line_array = line.split(' ')
          if line_array[0] =~ /[0-9]/
            log_debug("emgr: adding fix #{line_array[2]} to fixes list")
            array_fixes.push(line_array[2])
          end
          log_info("[STDOUT] #{line.chomp}")
        end
        stderr.each_line do |line|
          STDERR.puts line
          log_info("[STDERR] #{line.chomp}")
        end
        wait_thr.value # Process::Status object returned.
      end
      raise EmgrListError, "Error: Command \"#{emgr_s}\" returns above error!" unless exit_status.success?
      array_fixes
    end

    # -----------------------------------------------------------------
    # Remove fix with emgr
    #
    #    raise EmgrRemoveError in case of error
    # -----------------------------------------------------------------
    def remove_fix(machine, fix)
      emgr_s = "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{machine} \"/usr/sbin/emgr -r -L #{fix}\""
      log_debug("EMGR remove: #{emgr_s}")
      exit_status = Open3.popen3({ 'LANG' => 'C' }, emgr_s) do |_stdin, stdout, stderr, wait_thr|
        stdout.each_line do |line|
          log_info("[STDOUT] #{line.chomp}")
        end
        stderr.each_line do |line|
          STDERR.puts line
          log_info("[STDERR] #{line.chomp}")
        end
        wait_thr.value # Process::Status object returned.
      end
      raise EmgrRemoveError, "Error: Command \"#{emgr_s}\" returns above error!" unless exit_status.success?
    end

    # -----------------------------------------------------------------
    # Check lpp source exists
    #
    #    raise InvalidLppSourceProperty in case of error
    # -----------------------------------------------------------------
    def check_lpp_source_name(lpp_source, niminfo)
      raise InvalidLppSourceProperty, "lpp_source: '#{lpp_source}' does not exist." unless LppSource.exist?(lpp_source, niminfo)
      log_debug("Found lpp source #{lpp_source}")
    end

    # -----------------------------------------------------------------
    # Compute RqType suma parameter
    #    if oslevel not specified or == latest then return RqType = Latest
    #    if oslevel is a TL (6 digits) and target list empty then return RqType = Latest
    #    if oslevel is a TL (6 digits) or SP = 00 ou 00-0000 then return RqType = TL
    #    if a SP is specified (8 or 12 digits) then return RqType = SP
    #    raise InvalidOsLevelProperty in others cases
    # -----------------------------------------------------------------
    def compute_rq_type(oslevel, empty_list)
      return 'Latest' if oslevel.nil? || oslevel.empty? || oslevel.casecmp('latest') == 0
      return 'Latest' if oslevel =~ /^([0-9]{4}-[0-9]{2})$/ && empty_list
      return 'TL' if oslevel =~ /^([0-9]{4}-[0-9]{2})(|-00|-00-0000)$/
      return 'SP' if oslevel =~ /^([0-9]{4}-[0-9]{2}-[0-9]{2})(|-[0-9]{4})$/
      # else raise exception
      raise InvalidOsLevelProperty, 'Invalid Oslevel: "#{oslevel}"'
    end

    # -----------------------------------------------------------------
    # Compute RqName suma parameter
    #
    #   if oslevel is a complete SP (12 digits) then return RqName = oslevel
    #   if oslevel is an incomplete SP (8 digits) or oslevel=Latest then execute
    #   a metadata suma request to find the complete SP level (12 digits)
    #    raise InvalidTargetsProperty in case of error
    # -----------------------------------------------------------------
    def compute_rq_name(rq_type, oslevel, targets, niminfo)
      case rq_type
      when 'Latest'
        if targets.empty?
          metadata_filter_ml = oslevel[0..6]
          metadata_filter_ml << '-00' if metadata_filter_ml.size == 4
        else
          # build machine-oslevel hash
          levels = Hash.new { |h, k| h[k] = k == 'master' ? niminfo['nim']['master'].fetch('oslevel', nil) : niminfo['nim']['clients'].fetch(k, {}).fetch('oslevel', nil) }
          targets.each { |k| levels[k] }
          levels.delete_if { |_k, v| v.nil? || v.empty? }
          log_debug("Hash table (machine/oslevel) built #{levels}")

          unless levels.empty?
            # discover FilterML level
            ary = levels.values.collect { |v| v.match(/^([0-9]{4}-[0-9]{2})(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1].delete('-') }
            # find highest ML
            metadata_filter_ml = ary.max
            # check ml level of machines
            if ary.min[0..3].to_i < ary.max[0..3].to_i
              log_warn("Release level mismatch, only AIX #{ary.max[0]}.#{ary.max[1]} SP/TL will be downloaded")
            end
          end

          raise InvalidTargetsProperty, 'There is no target machine matching the requested oslevel.' if metadata_filter_ml.nil?
          metadata_filter_ml.insert(4, '-')
          log_info("Found highest ML #{metadata_filter_ml} from client list")
        end

        # suma metadata
        tmp_dir = ::File.join(Chef::Config[:file_cache_path], 'metadata')
        suma = Suma.new('DisplayName' => desc, 'RqType' => 'Latest', 'RqName' => nil, 'FilterML' => metadata_filter_ml, 'DLTarget' => tmp_dir)
        suma.metadata

        # find latest SP for highest TL
        sps = Dir.glob(::File.join(tmp_dir, 'installp', 'ppc', '*.install.tips.html'))
        sps.collect! do |file|
          file.gsub!('install.tips.html', 'xml')
          ::File.open(file) do |f|
            s = f.read
            #### BUG SUMA WORKAROUND ###
            s = s.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
            ########## END #############
            s.match(/^<SP name="([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})">$/)[1].delete('-')
          end
        end
        rq_name = sps.max
        unless rq_name.nil?
          rq_name.insert(4, '-')
          rq_name.insert(7, '-')
          rq_name.insert(10, '-')
        end
        FileUtils.rm_rf(tmp_dir)
        log_info("Discover RqName #{rq_name} with metadata suma command")

      when 'TL'
        # pad with 0
        rq_name = oslevel.match(/^([0-9]{4}-[0-9]{2})(|-00|-00-0000)$/)[1].to_s

      when 'SP'
        if oslevel =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}$/
          rq_name = oslevel
        elsif oslevel =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/
          # suma metadata
          metadata_filter_ml = oslevel.match(/^([0-9]{4}-[0-9]{2})-[0-9]{2}$/)[1]
          tmp_dir = ::File.join(Chef::Config[:file_cache_path], 'metadata')
          suma = Suma.new('DisplayName' => desc, 'RqType' => 'Latest', 'RqName' => nil, 'FilterML' => metadata_filter_ml, 'DLTarget' => tmp_dir)
          suma.metadata

          # find SP build number
          file_name = oslevel + '.xml'
          ::File.open(::File.join(tmp_dir, 'installp', 'ppc', file_name)) do |f|
            s = f.read
            #### BUG SUMA WORKAROUND ###
            s = s.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
            ########## END #############
            rq_name = s.match(/^<SP name="([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})">$/)[1]
          end
          FileUtils.rm_rf(tmp_dir)
          log_info("Discover RqName #{rq_name} with metadata suma command")
        end
      end
      rq_name
    end

    # -----------------------------------------------------------------
    # Compute FilterML suma parameter
    #
    #    if no taget machine is given then filter_ml = TL part (6 digits) of requested oslevel or rq_name
    #    else filter_ml = the lowest TL from target machines matching the release of the requested oslevel
    #    raise InvalidTargetsProperty in case of error
    # -----------------------------------------------------------------
    def compute_filter_ml(targets, rq_name, niminfo)
      # If there is no targets then the filter maintenance level = OSLevel part from rq_name
      if targets.nil? || targets.empty?
        filter_ml = rq_name[0..6]
        filter_ml << '-00' if filter_ml.size == 4
      else
        # build machine-oslevel hash
        levels = Hash.new { |h, k| h[k] = k == 'master' ? niminfo['nim']['master'].fetch('oslevel', nil) : niminfo['nim']['clients'].fetch(k, {}).fetch('oslevel', nil) }
        targets.each { |k| levels[k] }
        levels.delete_if { |_k, v| v.nil? || v.empty? || v.to_i != rq_name.to_i }
        log_debug("Hash table (machine/oslevel) built #{levels}")

        unless levels.empty?
          # discover FilterML level
          ary = levels.values.collect { |v| v.match(/^([0-9]{4}-[0-9]{2})(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1].delete('-') }
          # find lowest ML
          filter_ml = ary.min
        end
        raise InvalidSumaProperties, 'There is no target machine matching the requested oslevel.' if filter_ml.nil?
        filter_ml.insert(4, '-')
        log_warn("The oldest machine is at level #{filter_ml}.")
      end

      filter_ml
    end

    # -----------------------------------------------------------------
    # Compute lpp source name based on the location
    #
    # -----------------------------------------------------------------
    def compute_lpp_source_name(location, rq_name)
      lpp_src = ''
      oslevel = rq_name

      if location.nil? || location.empty? || location.start_with?('/')
        oslevel += '-00-0000' if oslevel =~ /^([0-9]{4}-[0-9]{2})$/
        lpp_src = "#{oslevel}-lpp_source"
      else
        lpp_src = location.chomp('\/')
      end

      lpp_src
    end

    # -----------------------------------------------------------------
    # Compute DLTarget suma parameter
    #
    #    raise InvalidLocationProperty in case of error
    # -----------------------------------------------------------------
    def compute_dl_target(location, lpp_source, niminfo)
      return ::File.join('usr', 'sys', 'inst.images', lpp_source) if location.nil? || location.empty?

      location.chomp!('\/')
      if location.start_with?('/') # location is a directory
        dl_target = ::File.join(location, lpp_source)
        # check if DLTarget match the one in lpp_source
        unless niminfo['nim']['lpp_sources'].fetch(lpp_source, {}).fetch('location', nil).nil?
          loc = niminfo['nim']['lpp_sources'][lpp_source]['location']
          log_debug("Found lpp source '#{lpp_source}' location: '#{loc}'")
          unless loc =~ /^#{dl_target}/
            raise InvalidLocationProperty, "Lpp source location mismatch. It already exist a lpp source '#{lpp_source}' with a location different as '#{dl_target}'"
          end
        end
      else # location is a lpp_source
        begin
          dl_target = niminfo['nim']['lpp_sources'].fetch(location).fetch('location')
          log_debug("Discover '#{location}' lpp source's location: '#{dl_target}'")
        rescue KeyError
          raise InvalidLocationProperty, "lpp_source: '#{location}' does not exist."
        end
      end
      dl_target
    end

    # -----------------------------------------------------------------
    # returns a hash with all suma params
    #
    # -----------------------------------------------------------------
    def suma_params(niminfo, desc, oslevel, location, targets)
      params = {}

      # build list of targets
      target_list = expand_targets(targets, niminfo['nim']['clients'].keys)
      log_debug("target_list=#{target_list}")
      empty_list = target_list.empty?
      params['DisplayName'] = desc
      oslevel.downcase!

      ############## Filter wrong cases ################
      if empty_list && (oslevel.nil? || oslevel.empty? || oslevel == 'latest')
        raise InvalidSumaProperties, "Oslevel target could not be empty or equal 'Latest' when target machine list is empty"
      end
      if oslevel =~ /^([0-9]{4})(|-00|-00-00|-00-00-0000)$/ && !empty_list
        raise InvalidOsLevelProperty, 'Specify a non 0 value for the Technical Level or the Service Pack'
      end
      if oslevel =~ /^([0-9]{4}-[0-9]{2})(-00|-00-0000)$/ && empty_list
        raise InvalidSumaProperties, 'When no Service Pack is provided , a target machine list is required'
      end
      # check "location" is a lpp_source
      check_lpp_source_name(location, niminfo) unless location.start_with?('/')
      ##################################################

      # compute suma request type based on oslevel property
      rq_type = compute_rq_type(oslevel, empty_list)
      log_debug("rq_type=#{rq_type}")
      params['RqType'] = rq_type

      # compute suma request name based on metadata info
      rq_name = compute_rq_name(rq_type, oslevel, target_list, niminfo)
      log_debug("rq_name=#{rq_name}")
      params['RqName'] = rq_name

      # metadata does not match any fixe
      return nil if params['RqName'].nil? || params['RqName'].empty?

      # compute suma filter ml based on targets property
      filter_ml = compute_filter_ml(target_list, rq_name, niminfo)
      log_debug("filter_ml=#{filter_ml}")
      params['FilterML'] = filter_ml

      # check ml level of machines against expected oslevel
      # case rq_type
      # when 'SP', 'TL'
      #   if filter_ml[0..3].to_i < oslevel.match(/^([0-9]{4})-[0-9]{2}(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1].to_i
      #     raise InvalidOsLevelProperty, 'Error: cannot upgrade machines to a new release using suma'
      #   end
      # end

      # compute lpp source name based on request name
      lpp_source = compute_lpp_source_name(location, rq_name)
      log_debug("lpp_source=#{lpp_source}")
      params['LppSource'] = lpp_source

      # compute suma dl target based on lpp source name
      dl_target = compute_dl_target(location, lpp_source, niminfo)
      log_debug("dl_target=#{dl_target}")
      params['DLTarget'] = dl_target

      # display user message
      log_info("The builded lpp_source will be: #{lpp_source}.")
      log_info("The lpp_source location will be: #{dl_target}.")
      log_info("The lpp_source will be available to update machines from #{filter_ml}-00 to #{rq_name}.")
      if rq_type == 'Latest'
        log_info("#{rq_name} is the Latest SP of TL #{filter_ml}.")
      end
      params['Comments'] = "Packages for updates from #{filter_ml} to #{rq_name}"

      params
    end

    # -----------------------------------------------------------------
    # Search for a lpp_source resource into available NIM resources
    #
    #    "type" : 'sp' or 'tl'
    #    "time" : 'latest' or 'next'
    #    "oslevel" : the oslevel of the machine for example 7100-01-01-1210
    #    "niminfo" : the hash to look lpp_source into
    #
    #    returns the corresponding lpp source if found
    #    or else the current oslevel
    # -----------------------------------------------------------------
    def find_resource_by_client(type, time, oslevel, niminfo)
      log_debug("nim: finding #{time} #{type}")
      lppsource = ''
      case type
      when 'tl'
        # reading output until I have found the good tl
        niminfo['nim']['lpp_sources'].keys.each do |key|
          a_key = key.split('-')
          next unless a_key[0] == oslevel[0] && a_key[1] > oslevel[1]
          lppsource = key
          break if time == 'next'
        end
      when 'sp'
        # reading output until I have found the good sp
        niminfo['nim']['lpp_sources'].keys.each do |key|
          a_key = key.split('-')
          next unless a_key[0] == oslevel[0] && a_key[1] == oslevel[1] && a_key[2] > oslevel[2]
          lppsource = key
          break if time == 'next'
        end
      end
      if lppsource.empty?
        # setting lpp_source to current oslevel if not found
        lppsource = oslevel[0] + '-' + oslevel[1] + '-' + oslevel[2] + '-' + oslevel[3] + '-lpp_source'
        log_debug("NIM: server already to the #{time} #{type}, or no lpp_source were found, #{lppsource} will be used")
      else
        log_debug("NIM: we found the #{time} lpp_source, #{lppsource} will be used")
      end
      lppsource
    end

    # -----------------------------------------------------------------
    # Expand the target vios pair list parameter
    #
    #    targets are in the form (vios1,vios2) (vios3,vios4) (vios5) (vios6)
    #
    #    for no altdisk checking altdisks should be nil otherwise
    #    it should be the keyword 'auto' or in the form
    #    (hdisk1,hdisk2) (hdisk1,) (hdisk5) ()
    #    with the same number of hdisk than VIOSes even if empty
    #
    #    raise InvalidTargetsProperty in case of error
    #    - cannot contact the target machines
    # -----------------------------------------------------------------
    def expand_vios_pair_targets(targets, vios_nim_list, altdisks, altdisk_hash)
      selected_vios = []
      vios_list = []

      vios_list_tuples = targets.gsub(' ','').gsub('),(', ')(').split('(')
      vios_list_tuples.delete_at(0) # after the split, 1rst elt is nil

      unless altdisks.nil? || altdisks == "auto"
        # TBC VRO: we use gsub to remove spaces then we add them back? 
        # hd_list_tuples = altdisks.gsub(' ','').gsub('),(', ')(').split('(')
        altdisks.gsub(' ','').gsub('),(', ')(')
        hd_list_tuples = altdisks.gsub('(,', '( ,').gsub(',)', ', )').split('(')
        hd_list_tuples.delete_at(0)
        if hd_list_tuples.length != vios_list_tuples.length
          raise InvalidTargetsProperty, "Error: Alternate hdisks '#{altdisks}' and vios target '#{targets}' must have the same number of element"
        end
      end

      # Build targets list
      hd_tuple_index = 0
      vios_list_tuples.each do |vios_tuple|
        my_tuple = vios_tuple.gsub(')','')
        tuple_elts = my_tuple.split(',')
        tuple_len = tuple_elts.length

        # check targets has the form of (vios1,vios2) or (vios3)
        if tuple_len != 1 && tuple_len != 2
          raise InvalidTargetsProperty, "Error: Malformed vios targets '#{targets}'"
        end

        # check vios not already exists in the target list
        if vios_list.include?(tuple_elts[0]) ||
           (tuple_len == 2 && (vios_list.include?(tuple_elts[1]) ||
            tuple_elts[0] == tuple_elts[1]))
          raise InvalidTargetsProperty, "Error: Malformed vios targets, Duplicated values '#{targets}'"
        end

        # check vios is knowed by the NIM master - if not ignore it
        if !vios_nim_list.include?(tuple_elts[0]) ||
           tuple_len == 2 && !vios_nim_list.include?(tuple_elts[1])
          next
        end

        if tuple_len == 2
          vios_list.push(tuple_elts[0], tuple_elts[1])
        else
          vios_list.push(tuple_elts[0])
        end
        selected_vios.push(my_tuple)

        # Handle hdisk list if altdisks not nil
        next if altdisks.nil?

        # in auto mode, just add empty hdisk for the 2 vioses
        if altdisks == "auto"
          altdisk_hash[tuple_elts[0]] = ""
          altdisk_hash[tuple_elts[1]] = ""
          next
        end

        # parse the hdisk tuple
        hd_tuple = hd_list_tuples[hd_tuple_index].gsub(')','')
        hd_tuple_elts = hd_tuple.split(',')
        hd_tuple_len = hd_tuple_elts.length
        if hd_tuple_len != tuple_len
          raise InvalidTargetsProperty, "Error: alternate hdsik tuple '#{hd_tuple}' and vios tuple '#{my_tuple}' must have the same number of element"
        end
        altdisk_hash[tuple_elts[0]] = hd_tuple_elts[0].gsub(' ', '')
        if tuple_len == 2
          altdisk_hash[tuple_elts[1]] = hd_tuple_elts[1].gsub(' ', '')
        end

        hd_tuple_index += 1
      end

      if selected_vios.empty?
        raise InvalidTargetsProperty, "Error: cannot contact any machines in '#{targets}'"
      end

      log_info("List of targets expanded to #{selected_vios}")
      log_info("List of altdisk: #{altdisk_hash}")
      selected_vios
    end

  end  # module PatchMgmt
end  # module AIX
