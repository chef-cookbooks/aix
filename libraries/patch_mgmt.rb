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
    def log_debug(message)
      Chef::Log.debug(message)
      #STDERR.puts('DEBUG : ' + message)
    end

    def log_info(message)
      Chef::Log.info(message)
      #puts('INFO : ' + message)
    end

    def log_warn(message)
      Chef::Log.warn(message)
      #puts('WARN : ' + message)
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
      include Chef::Mixin::ShellOut
      include AIX::PatchMgmt

      attr_reader :dl
      attr_reader :downloaded
      attr_reader :failed
      attr_reader :skipped

      def initialize(display_name, rq_type, rq_name, filter_ml, dl_target)
        @display_name = display_name
        @rq_type = rq_type
        @rq_name = rq_name
        @filter_ml = filter_ml
        @dl_target = dl_target
        ::FileUtils.mkdir_p(@dl_target) unless ::File.directory?(@dl_target)
        #### BUG SUMA WORKAROUND ###
        ::FileUtils.mkdir_p('/usr/sys/inst.images') unless ::File.directory?('/usr/sys/inst.images')
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

      def metadata(save_it = false)
        suma_s = "/usr/sbin/suma -x -a Action=Metadata -a DisplayName=\"#{@display_name}\"  -a RqType=#{@rq_type} -a FilterML=#{@filter_ml} -a DLTarget=#{@dl_target}"
        case @rq_type
        when 'SP'
          suma_s << " -a RqName=#{@rq_name}"
        when 'TL'
          suma_s << " -a RqName=#{@rq_name.match(/^([0-9]{4}-[0-9]{2})-00-0000$/)[1]}"
        end
        suma_s << (save_it ? ' -w' : '')

        log_debug("SUMA metadata operation: #{suma_s}")
        so = shell_out(suma_s, environment: { 'LANG' => 'C' }, timeout: 3000)
        so.stdout.each_line do |line|
          log_info("[STDOUT] #{line.chomp}")
        end
        so.stderr.each_line do |line|
          if line =~ /Task ID ([0-9]+) created./
            log_warn("Created task #{Regexp.last_match(1)}")
          end
          log_info("[STDERR] #{line.chomp}")
        end
        if so.stderr =~ /^0500-035 No fixes match your query.$/
          log_info("Done suma metadata operation \"#{suma_s}\"")
        elsif so.error?
          raise SumaMetadataError, "Error: Command \"#{suma_s}\" returns:\n--- STDERR ---\n#{so.stderr.chomp!}\n--- STDOUT ---\n#{so.stdout.chomp!}\n--------------"
        else
          log_info("Done suma metadata operation \"#{suma_s}\"")
        end
      end

      def preview(save_it = false)
        suma_s = "/usr/sbin/suma -x -a Action=Preview -a DisplayName=\"#{@display_name}\" -a RqType=#{@rq_type} -a FilterML=#{@filter_ml} -a DLTarget=#{@dl_target}"
        case @rq_type
        when 'SP'
          suma_s << " -a RqName=#{@rq_name}"
        when 'TL'
          suma_s << " -a RqName=#{@rq_name.match(/^([0-9]{4}-[0-9]{2})-00-0000$/)[1]}"
        end
        suma_s << (save_it ? ' -w' : '')

        log_debug("SUMA preview operation: #{suma_s}")
        so = shell_out(suma_s, environment: { 'LANG' => 'C' }, timeout: 3000)
        so.stdout.each_line do |line|
          log_info("[STDOUT] #{line.chomp}")
        end
        so.stderr.each_line do |line|
          if line =~ /Task ID ([0-9]+) created./
            log_warn("Created task #{Regexp.last_match(1)}")
          end
          log_info("[STDERR] #{line.chomp}")
        end
        if so.stderr =~ /^0500-035 No fixes match your query.$/
          log_info("Done suma preview operation \"#{suma_s}\"")
        elsif so.stdout =~ /Total bytes of updates downloaded: ([0-9]+).*?([0-9]+) downloaded.*?([0-9]+) failed.*?([0-9]+) skipped/m
          @dl = Regexp.last_match(1).to_f / 1024 / 1024 / 1024
          @downloaded = Regexp.last_match(2)
          @failed = Regexp.last_match(3)
          @skipped = Regexp.last_match(4)
          log_debug(so.stdout)
          log_warn("Preview: #{@downloaded} downloaded (#{@dl.to_f.round(2)} GB), #{@failed} failed, #{@skipped} skipped fixes")
          log_info("Done suma preview operation \"#{suma_s}\"")
        else
          raise SumaPreviewError, "Error: Command \"#{suma_s}\" returns:\n--- STDERR ---\n#{so.stderr.chomp!}\n--- STDOUT ---\n#{so.stdout.chomp!}\n--------------"
        end
      end

      def download(save_it = false)
        suma_s = "/usr/sbin/suma -x -a Action=Download -a DisplayName=\"#{@display_name}\" -a RqType=#{@rq_type} -a FilterML=#{@filter_ml} -a DLTarget=#{@dl_target}"
        case @rq_type
        when 'SP'
          suma_s << " -a RqName=#{@rq_name}"
        when 'TL'
          suma_s << " -a RqName=#{@rq_name.match(/^([0-9]{4}-[0-9]{2})-00-0000$/)[1]}"
        end
        suma_s << ' -w' if save_it

        succeeded = 0
        failed = 0
        skipped = 0
        download_downloaded = 0
        download_failed = 0
        download_skipped = 0
        puts "\nStart downloading #{@downloaded} fixes (~ #{@dl.to_f.round(2)} GB) to '#{@dl_target}' directory."
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
        raise SumaDownloadError, "Error: Command \"#{suma_s}\" returns above error!" unless exit_status.success?
        puts "\nFinish downloading #{succeeded} fixes."
        @download = download_downloaded
        @failed = download_failed
        @skipped = download_skipped
      end
    end

    #################
    #     N I M     #
    #################
    class Nim
      include Chef::Mixin::ShellOut
      include AIX::PatchMgmt

      def exist?(resource)
        !shell_out("lsnim | grep #{resource}").error?
      end

      def define_lpp_source(lpp_source, dl_target)
        nim_s = "/usr/sbin/nim -o define -t lpp_source -a server=master -a location=#{dl_target} #{lpp_source}"
        so = shell_out(nim_s)
        so.stdout.each_line do |line|
          log_info("[STDOUT] #{line.chomp}")
        end
        so.stderr.each_line do |line|
          log_info("[STDERR] #{line.chomp}")
        end
        raise NimDefineError, "Error: Command \"#{nim_s}\" returns:\n--- STDERR ---\n#{so.stderr.chomp!}\n--- STDOUT ---\n#{so.stdout.chomp!}\n--------------" if so.error?
        log_info("Done nim define operation \"#{nim_s}\"")
      end

      def remove_resource(resource)
        nim_s = "/usr/sbin/nim -o remove #{resource}"
        so = shell_out(nim_s)
        so.stdout.each_line do |line|
          log_info("[STDOUT] #{line.chomp}")
        end
        so.stderr.each_line do |line|
          log_info("[STDERR] #{line.chomp}")
        end
        raise NimDefineError, "Error: Command \"#{nim_s}\" returns:\n--- STDERR ---\n#{so.stderr.chomp!}\n--- STDOUT ---\n#{so.stdout.chomp!}\n--------------" if so.error?
        log_info("Done nim remove operation \"#{nim_s}\"")
      end

      def perform_customization(lpp_source, clients, async = true)
        async_s = async ? 'yes' : 'no'
        nim_s = "/usr/sbin/nim -o cust -a lpp_source=#{lpp_source} -a fixes=update_all -a accept_licenses=yes -a async=#{async_s} #{clients}"
        puts "\nStart updating machine(s) '#{clients}' to #{lpp_source}."
        if async # asynchronous
          so = shell_out(nim_s, environment: { 'LANG' => 'C' }, timeout: 3000)
          so.stdout.each_line do |line|
            log_info("[STDOUT] #{line.chomp}")
          end
          so.stderr.each_line do |line|
            log_info("[STDERR] #{line.chomp}")
          end
          raise NimCustError, "Error: Command \"#{nim_s}\" returns:\n--- STDERR ---\n#{so.stderr.chomp!}\n--- STDOUT ---\n#{so.stdout.chomp!}\n--------------" if so.error? && so.stdout !~ /Either the software is already at the same level as on the media, or/m
          log_info("Done nim customize operation \"#{nim_s}\"")
        else # synchronous
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
          puts "\nFinish updating #{clients}."
          raise NimCustError, "Error: Command \"#{nim_s}\" returns above error!" unless exit_status.success? || do_not_error
        end
      end

      def perform_efix_customization(lpp_source, client)
        nim_s = "/usr/sbin/nim -o cust -a lpp_source=#{lpp_source} -a filesets=all #{client}"
        puts "\nStart patching machine(s) '#{client}'."
        exit_status = Open3.popen3({ 'LANG' => 'C' }, nim_s) do |_stdin, stdout, stderr, wait_thr|
          stdout.each_line do |line|
            print "\033[2K\r#{line.chomp}" if line =~ /^Processing Efix Package .*?[0-9]+ of .*?[0-9]+.$/
            puts line if line =~ /^EPKG NUMBER/ || line =~ /^===========/ || line =~ /INSTALL/
            log_info("[STDOUT] #{line.chomp}")
          end
          stderr.each_line do |line|
            puts line
            log_info("[STDERR] #{line.chomp}")
          end
          wait_thr.value # Process::Status object returned.
        end
        puts "\nFinish patching #{client}."
        raise NimCustError, "Error: Command \"#{nim_s}\" returns above error!" unless exit_status.success?
      end
    end

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
    # Check nim hash info is well configured
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
      raise NimInfoNotFound, 'Error: cannot find nim info'
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
      return ['master'] if targets.nil? || targets.empty?

      selected_machines = []
      targets.split(/[,\s]/).each do |machine|
        selected_machines.push(machine) if machine == 'master'
        # expand wildcard
        machine.gsub!(/\*/, '.*?')
        clients.each do |m|
          selected_machines.concat(m.split) if m =~ /^#{machine}$/
        end
      end
      raise InvalidTargetsProperty, "Error: cannot contact any machines in '#{targets}'" if selected_machines.empty?
      selected_machines = selected_machines.sort.uniq
      log_info("List of targets expanded to #{selected_machines}")
      selected_machines
    end

    # -----------------------------------------------------------------
    # Check lpp source exists
    #
    #    raise InvalidLppSourceProperty in case of error
    # -----------------------------------------------------------------
    def check_lpp_source_name(lpp_source, niminfo)
      raise InvalidLppSourceProperty, "Error: cannot find lpp_source '#{lpp_source}'" unless LppSource.exist?(lpp_source, niminfo)
      log_debug("Found lpp source #{lpp_source}") 
    end

    # -----------------------------------------------------------------
    # Compute RqType suma parameter
    #
    #    raise InvalidOsLevelProperty in case of error
    # -----------------------------------------------------------------
    def compute_rq_type(oslevel)
      return 'Latest' if oslevel.nil? || oslevel.empty? || oslevel.casecmp('latest').zero?
      return 'TL' if oslevel =~ /^([0-9]{4}-[0-9]{2})(|-00|-00-0000)$/
      return 'SP' if oslevel =~ /^([0-9]{4}-[0-9]{2}-[0-9]{2})(|-[0-9]{4})$/
      # else raise exception
      raise InvalidOsLevelProperty, 'Error: oslevel is not recognized'
    end

    # -----------------------------------------------------------------
    # Compute RqName suma parameter
    #
    #    raise InvalidTargetsProperty in case of error
    # -----------------------------------------------------------------
    def compute_rq_name(rq_type, targets, niminfo)
      case rq_type
      when 'Latest'
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
        raise InvalidTargetsProperty, 'Error: cannot discover filter ml based on the list of targets' if metadata_filter_ml.nil?
        metadata_filter_ml.insert(4, '-')
        log_info("Found highest ML #{metadata_filter_ml} from client list")

        # suma metadata
        tmp_dir = "#{Chef::Config[:file_cache_path]}/metadata"
        suma = Suma.new(desc, 'Latest', nil, metadata_filter_ml, tmp_dir)
        suma.metadata

        # find latest SP for highest TL
        sps = shell_out("ls #{tmp_dir}/installp/ppc/*.install.tips.html").stdout.split
        sps.collect! do |file|
          file.gsub!('install.tips.html', 'xml')
          ::File.open(file) do |f|
            f.read.match(/^<SP name="([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})">$/)[1].delete('-')
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
        rq_name = "#{oslevel.match(/^([0-9]{4}-[0-9]{2})(|-00|-00-0000)$/)[1]}-00-0000"

      when 'SP'
        if oslevel =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}$/
          rq_name = oslevel
        elsif oslevel =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/
          # suma metadata
          metadata_filter_ml = oslevel.match(/^([0-9]{4}-[0-9]{2})-[0-9]{2}$/)[1]
          tmp_dir = "#{Chef::Config[:file_cache_path]}/metadata"
          suma = Suma.new(desc, 'Latest', nil, metadata_filter_ml, tmp_dir)
          suma.metadata

          # find SP build number
          ::File.open("#{tmp_dir}/installp/ppc/#{oslevel}.xml") do |f|
            rq_name = f.read.match(/^<SP name="([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})">$/)[1]
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
    #    raise InvalidTargetsProperty in case of error
    # -----------------------------------------------------------------
    def compute_filter_ml(targets, rq_name, niminfo)
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

      raise InvalidTargetsProperty, 'Error: cannot discover filter ml based on the list of targets' if filter_ml.nil?
      filter_ml.insert(4, '-')
      filter_ml
    end

    # -----------------------------------------------------------------
    # Compute lpp source name based on the location
    #
    # -----------------------------------------------------------------
    def compute_lpp_source_name(location, rq_name)
      return "#{rq_name}-lpp_source" if location.nil? || location.empty? || location.start_with?('/')
      # else
      location.chomp('\/')
    end

    # -----------------------------------------------------------------
    # Compute DLTarget suma parameter
    #
    #    raise InvalidLocationProperty in case of error
    # -----------------------------------------------------------------
    def compute_dl_target(location, lpp_source, niminfo)
      return "/usr/sys/inst.images/#{lpp_source}" if location.nil? || location.empty?

      location.chomp!('\/')
      if location.start_with?('/') # location is a directory
        dl_target = "#{location}/#{lpp_source}"
        # check if DLTarget match the one in lpp_source
        unless niminfo['nim']['lpp_sources'].fetch(lpp_source, {}).fetch('location', nil).nil?
          log_debug("Found lpp source '#{lpp_source}' location")
          unless niminfo['nim']['lpp_sources'][lpp_source]['location'] =~ /^#{dl_target}/
            raise InvalidLocationProperty, 'Error: lpp source location mismatch'
          end
        end
      else # location is a lpp_source
        begin
          dl_target = niminfo['nim']['lpp_sources'].fetch(location).fetch('location')
          log_debug("Discover '#{location}' lpp source's location: '#{dl_target}'")
        rescue KeyError
          raise InvalidLocationProperty, "Error: cannot find lpp_source '#{location}' from nim info"
        end
      end
      dl_target
    end

    # -----------------------------------------------------------------
    # returns a hash with all suma params
    #
    # -----------------------------------------------------------------
    def suma_params(niminfo)
      params = {}

      # build list of targets
      target_list = expand_targets(targets, niminfo['nim']['clients'].keys)
      log_debug("target_list=#{target_list}")

      # compute suma request type based on oslevel property
      rq_type = compute_rq_type(oslevel)
      log_debug("rq_type=#{rq_type}")
      params['rq_type'] = rq_type

      # compute suma request name based on metadata info
      rq_name = compute_rq_name(rq_type, target_list, niminfo)
      log_debug("rq_name=#{rq_name}")
      params['rq_name'] = rq_name

      # metadata does not match any fixes
      return nil if params['rq_name'].nil? || params['rq_name'].empty?

      # compute suma filter ml based on targets property
      filter_ml = compute_filter_ml(target_list, rq_name, niminfo)
      log_debug("filter_ml=#{filter_ml}")
      params['filter_ml'] = filter_ml

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
      params['lpp_source'] = lpp_source

      # compute suma dl target based on lpp source name
      dl_target = compute_dl_target(location, lpp_source, niminfo)
      log_debug("dl_target=#{dl_target}")
      params['dl_target'] = dl_target

      params
    end

    # -----------------------------------------------------------------
    # Search for a lpp_source resource into available nim resources
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
        log_debug("nim: server already to the #{time} #{type}, or no lpp_source were found, #{lppsource} will be utilized")
      else
        log_debug("nim: we found the #{time} lpp_source, #{lppsource} will be utilized")
      end
      lppsource
    end
  end
end
