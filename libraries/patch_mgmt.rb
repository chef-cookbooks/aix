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
    #############################
    #     E X C E P T I O N     #
    #############################
    class OhaiNimPluginNotFound < StandardError
    end

    class InvalidLppSourceProperty < StandardError
    end

    class InvalidTargetsProperty < StandardError
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

    ###################
    #     S U M A     #
    ###################
    class Suma
      include Chef::Mixin::ShellOut

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

        Chef::Log.debug("SUMA metadata operation: #{suma_s}")
        so = shell_out(suma_s, environment: { 'LANG' => 'C' }, timeout: 3000)
        so.stdout.each_line do |line|
          Chef::Log.info("[STDOUT] #{line.chomp}")
        end
        so.stderr.each_line do |line|
          if line =~ /Task ID ([0-9]+) created./
            Chef::Log.warn("Created task #{Regexp.last_match(1)}")
          end
          Chef::Log.info("[STDERR] #{line.chomp}")
        end
        if so.stderr =~ /^0500-035 No fixes match your query.$/
          Chef::Log.info("Done suma metadata operation \"#{suma_s}\"")
        elsif so.error?
          raise SumaMetadataError, "Error: Command \"#{suma_s}\" returns:\n--- STDERR ---\n#{so.stderr.chomp!}\n--- STDOUT ---\n#{so.stdout.chomp!}\n--------------"
        else
          Chef::Log.info("Done suma metadata operation \"#{suma_s}\"")
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

        Chef::Log.debug("SUMA preview operation: #{suma_s}")
        so = shell_out(suma_s, environment: { 'LANG' => 'C' }, timeout: 3000)
        so.stdout.each_line do |line|
          Chef::Log.info("[STDOUT] #{line.chomp}")
        end
        so.stderr.each_line do |line|
          if line =~ /Task ID ([0-9]+) created./
            Chef::Log.warn("Created task #{Regexp.last_match(1)}")
          end
          Chef::Log.info("[STDERR] #{line.chomp}")
        end
        if so.stderr =~ /^0500-035 No fixes match your query.$/
          Chef::Log.info("Done suma preview operation \"#{suma_s}\"")
        elsif so.stdout =~ /Total bytes of updates downloaded: ([0-9]+).*?([0-9]+) downloaded.*?([0-9]+) failed.*?([0-9]+) skipped/m
          @dl = Regexp.last_match(1).to_f / 1024 / 1024 / 1024
          @downloaded = Regexp.last_match(2)
          @failed = Regexp.last_match(3)
          @skipped = Regexp.last_match(4)
          Chef::Log.debug(so.stdout)
          Chef::Log.warn("Preview: #{@downloaded} downloaded (#{@dl.to_f.round(2)} GB), #{@failed} failed, #{@skipped} skipped fixes")
          Chef::Log.info("Done suma preview operation \"#{suma_s}\"")
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
        suma_s << (save_it ? ' -w' : '')

        succeeded = 0
        failed = 0
        skipped = 0
        download_downloaded = 0
        download_failed = 0
        download_skipped = 0
        puts "\nStart downloading #{@downloaded} fixes (~ #{@dl.to_f.round(2)} GB) to '#{@dl_target}' directory."
        exit_status = Open3.popen3({ 'LANG' => 'C' }, suma_s) do |stdin, stdout, stderr, wait_thr|
          thr = Thread.new do
            start = Time.now
            loop do
              print "\033[2K\rSUCCEEDED: #{succeeded}/#{@downloaded}\tFAILED: #{failed}/#{@failed}\tSKIPPED: #{skipped}/#{@skipped}. (Total time: #{duration(Time.now - start)})."
              sleep 1
            end
          end
          stdin.close
          stdout.each_line do |line|
            if line =~ /^Download SUCCEEDED:/
              succeeded += 1
            elsif line =~ /^Download FAILED:/
              failed += 1
            elsif line =~ /^Download SKIPPED:/
              skipped += 1
            elsif line =~ /([0-9]+) downloaded/
              download_downloaded = Regexp.last_match(1)
            elsif line =~ /([0-9]+) failed/
              download_failed = Regexp.last_match(1)
            elsif line =~ /([0-9]+) skipped/
              download_skipped = Regexp.last_match(1)
            elsif line =~ /(Total bytes of updates downloaded|Summary|Partition id|Filesystem size changed to|### SUMA FAKE)/
              # do nothing
            else
              puts "\n#{line}"
            end
            Chef::Log.info("[STDOUT] #{line.chomp}")
            stdout.flush
          end
          stdout.close
          stderr.each_line do |line|
            if line =~ /Task ID ([0-9]+) created./
              Chef::Log.warn("Created task #{Regexp.last_match(1)}")
            else
              puts line
            end
            Chef::Log.info("[STDERR] #{line.chomp}")
          end
          stderr.close
          thr.exit
          wait_thr.value # Process::Status object returned.
        end
        unless exit_status.success?
          raise SumaDownloadError, "Error: Command \"#{suma_s}\" returns above error!"
        end
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

      def initialize
      end

      def exist?(resource)
        !shell_out("lsnim | grep #{resource}").error?
      end

      def define_lpp_source(lpp_source, dl_target)
        nim_s = "/usr/sbin/nim -o define -t lpp_source -a server=master -a location=#{dl_target} #{lpp_source}"
        so = shell_out(nim_s)
        so.stdout.each_line do |line|
          Chef::Log.info("[STDOUT] #{line.chomp}")
        end
        so.stderr.each_line do |line|
          Chef::Log.info("[STDERR] #{line.chomp}")
        end
        if so.error?
          raise NimDefineError, "Error: Command \"#{nim_s}\" returns:\n--- STDERR ---\n#{so.stderr.chomp!}\n--- STDOUT ---\n#{so.stdout.chomp!}\n--------------"
        else
          Chef::Log.info("Done nim define operation \"#{nim_s}\"")
        end
      end

      def remove_resource(resource)
        nim_s = "/usr/sbin/nim -o remove #{resource}"
        so = shell_out(nim_s)
        so.stdout.each_line do |line|
          Chef::Log.info("[STDOUT] #{line.chomp}")
        end
        so.stderr.each_line do |line|
          Chef::Log.info("[STDERR] #{line.chomp}")
        end
        if so.error?
          raise NimDefineError, "Error: Command \"#{nim_s}\" returns:\n--- STDERR ---\n#{so.stderr.chomp!}\n--- STDOUT ---\n#{so.stdout.chomp!}\n--------------"
        else
          Chef::Log.info("Done nim remove operation \"#{nim_s}\"")
        end
      end

      def perform_customization(lpp_source, clients, async = true)
        async_s = async ? 'yes' : 'no'
        nim_s = "/usr/sbin/nim -o cust -a lpp_source=#{lpp_source} -a fixes=update_all -a accept_licenses=yes -a async=#{async_s} #{clients}"
        puts "\nStart updating machine(s) '#{clients}' to #{lpp_source}."
        if async # asynchronous
          so = shell_out(nim_s, environment: { 'LANG' => 'C' }, timeout: 3000)
          so.stdout.each_line do |line|
            Chef::Log.info("[STDOUT] #{line.chomp}")
          end
          so.stderr.each_line do |line|
            Chef::Log.info("[STDERR] #{line.chomp}")
          end
          if so.error? && so.stdout !~ /Either the software is already at the same level as on the media, or/m
            raise NimCustError, "Error: Command \"#{nim_s}\" returns:\n--- STDERR ---\n#{so.stderr.chomp!}\n--- STDOUT ---\n#{so.stdout.chomp!}\n--------------"
          else
            Chef::Log.info("Done nim customize operation \"#{nim_s}\"")
          end
        else # synchronous
          do_not_error = false
          exit_status = Open3.popen3({ 'LANG' => 'C' }, nim_s) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            stdout.each_line do |line|
              if line =~ /^Filesets processed:.*?[0-9]+ of [0-9]+/
                print "\033[2K\r#{line.chomp}"
              elsif line =~ /^Finished processing all filesets./
                print "\033[2K\r#{line.chomp}"
              end
              Chef::Log.info("[STDOUT] #{line.chomp}")
            end
            stdout.close
            stderr.each_line do |line|
              if line =~ /Either the software is already at the same level as on the media, or/
                do_not_error = true
              end
              puts line
              Chef::Log.info("[STDERR] #{line.chomp}")
            end
            stderr.close
            wait_thr.value # Process::Status object returned.
          end
          puts "\nFinish updating #{clients}."
          unless exit_status.success? || do_not_error
            raise NimCustError, "Error: Command \"#{nim_s}\" returns above error!"
          end
        end
      end

      def perform_efix_customization(lpp_source, client)
        nim_s = "/usr/sbin/nim -o cust -a lpp_source=#{lpp_source} -a filesets=all #{client}"
        puts "\nStart patching machine(s) '#{client}'."
        exit_status = Open3.popen3({ 'LANG' => 'C' }, nim_s) do |stdin, stdout, stderr, wait_thr|
          stdin.close
          stdout.each_line do |line|
            if line =~ /^Processing Efix Package .*?[0-9]+ of .*?[0-9]+.$/
              print "\033[2K\r#{line.chomp}"
            elsif line =~ /^EPKG NUMBER/ || line =~ /^===========/ || line =~ /INSTALL/
              puts line
            end
            Chef::Log.info("[STDOUT] #{line.chomp}")
          end
          stdout.close
          stderr.each_line do |line|
            puts line
            Chef::Log.info("[STDERR] #{line.chomp}")
          end
          stderr.close
          wait_thr.value # Process::Status object returned.
        end
        puts "\nFinish patching #{client}."
        unless exit_status.success?
          raise NimCustError, "Error: Command \"#{nim_s}\" returns above error!"
        end
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
        widths[key] = (val_len > widths[key]) ? val_len : widths[key]
        # length of key
        widths[key] = (key.to_s.length > widths[key]) ? key.to_s.length : widths[key]
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
    # Check ohai nim plugin has been run
    #
    #    raise OhaiNimPluginNotFound in case of error
    # -----------------------------------------------------------------
    def check_ohai
      # get list of all NIM machines from Ohai
      master = node.fetch('nim', {}).fetch('master').fetch('oslevel')
      Chef::Log.debug("Ohai master oslevel is #{master}")
      all_machines = node.fetch('nim', {}).fetch('clients').keys
      Chef::Log.debug("Ohai client machine's list is #{all_machines}")
      all_lpp_sources = node.fetch('nim', {}).fetch('lpp_sources').keys
      Chef::Log.debug("Ohai lpp source's list is #{all_lpp_sources}")
    rescue KeyError
      raise OhaiNimPluginNotFound, 'Error: cannot find nim info from Ohai output'
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
    def expand_targets(clients)
      selected_machines = []
      # compute list of machines based on targets property
      if property_is_set?(:targets)
        if !targets.empty?
          targets.split(/[,\s]/).each do |machine|
            selected_machines.push(machine) if machine == 'master'
            # expand wildcard
            machine.gsub!(/\*/, '.*?')
            clients.each do |m|
              selected_machines.concat(m.split) if m =~ /^#{machine}$/
            end
          end
          selected_machines = selected_machines.sort.uniq
        else # empty
          selected_machines.push('master')
        end
      else # not set
        selected_machines.push('master')
      end
      Chef::Log.info("List of targets expanded to #{selected_machines}")

      if selected_machines.empty?
        raise InvalidTargetsProperty, "Error: cannot contact any machines in '#{targets}'"
      end
      selected_machines
    end

    # -----------------------------------------------------------------
    # Check lpp source exists
    #
    #    raise InvalidLppSourceProperty in case of error
    # -----------------------------------------------------------------
    def check_lpp_source_name(lpp_source)
      if node['nim']['lpp_sources'].fetch(lpp_source)
        Chef::Log.debug("Found lpp source #{lpp_source}")
      end
    rescue KeyError
      raise InvalidLppSourceProperty, "Error: cannot find lpp_source '#{lpp_source}' from Ohai output"
    end

    # -----------------------------------------------------------------
    # Search for a lpp_source resource into available nim resources
    #
    #    "type" : 'sp' or 'tl'
    #    "time" : 'latest' or 'next'
    #    "oslevel" : the oslevel of the machine for example 7100-01-01-1210
    #
    #    returns the corresponding lpp source if found
    #    or else the current oslevel
    # -----------------------------------------------------------------
    def find_resource_by_client(type, time, oslevel)
      Chef::Log.debug("nim: finding #{time} #{type}")
      lppsource = ''
      case type
      when 'tl'
        # reading output until I have found the good tl
        node['nim']['lpp_sources'].keys.each do |key|
          a_key = key.split('-')
          next unless a_key[0] == oslevel[0] && a_key[1] > oslevel[1]
          lppsource = key
          break if time == 'next'
        end
      when 'sp'
        # reading output until I have found the good sp
        node['nim']['lpp_sources'].keys.each do |key|
          a_key = key.split('-')
          next unless a_key[0] == oslevel[0] && a_key[1] == oslevel[1] && a_key[2] > oslevel[2]
          lppsource = key
          break if time == 'next'
        end
      end
      if lppsource.empty?
        # setting lpp_source to current oslevel if not found
        lppsource = oslevel[0] + '-' + oslevel[1] + '-' + oslevel[2] + '-' + oslevel[3] + '-lpp_source'
        Chef::Log.debug("nim: server already to the #{time} #{type}, or no lpp_source were found, #{lppsource} will be utilized")
      else
        Chef::Log.debug("nim: we found the #{time} lpp_source, #{lppsource} will be utilized")
      end
      lppsource
    end
  end
end
