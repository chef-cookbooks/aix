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
    class OhaiNimPluginNotFound < StandardError
    end

    class InvalidOsLevelProperty < StandardError
    end

    class InvalidLocationProperty < StandardError
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

    class OsLevel
      include Comparable
      attr_reader :str

      def <=>(other)
        if @str.delete('-').to_i < other.str.delete('-').to_i
          -1
        elsif @str.delete('-').to_i > other.str.delete('-').to_i
          1
        else
          0
        end
      end

      def initialize(str)
        @str = str
      end
    end

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
      end

      def metadata(save_it = false)
        suma_s = "/usr/sbin/suma -x -a Action=Metadata -a DisplayName=\"#{@display_name}\"  -a RqType=#{@rq_type} -a FilterML=#{@filter_ml} -a DLTarget=#{@dl_target}"
        case @rq_type
        when 'SP'
          suma_s << " -a RqName=#{@rq_name}"
        when 'TL'
          suma_s << " -a RqName=#{@rq_name.match(/^([0-9]{4}-[0-9]{2})-00-0000$/)[1]}"
        end
        suma_s << ( save_it ? ' -w' : '' )

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
        if so.error?
          raise SumaMetadataError, "Error: Command \"#{suma_s}\" returns:\n--- STDERR ---\n#{so.stderr.chomp!}\n--- STDOUT ---\n#{so.stdout.chomp!}\n--------------"
        else
          Chef::Log.warn("Done suma metadata operation \"#{suma_s}\"")
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
        suma_s << ( save_it ? ' -w' : '' )

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
          Chef::Log.warn("Done suma preview operation \"#{suma_s}\"")
        elsif so.stdout =~ /Total bytes of updates downloaded: ([0-9]+).*?([0-9]+) downloaded.*?([0-9]+) failed.*?([0-9]+) skipped/m
          @dl = so.stdout.match(/Total bytes of updates downloaded: ([0-9]+)/)[1].to_f / 1024 / 1024 / 1024
          @downloaded = so.stdout.match(/([0-9]+) downloaded/)[1]
          @failed = so.stdout.match(/([0-9]+) failed/)[1]
          @skipped = so.stdout.match(/([0-9]+) skipped/)[1]
          Chef::Log.debug(so.stdout)
          Chef::Log.info("#{@downloaded} downloaded (#{@dl} GB), #{@failed} failed, #{@skipped} skipped fixes")
          Chef::Log.warn("Done suma preview operation \"#{suma_s}\"")
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
        suma_s << ( save_it ? ' -w' : '' )

        succeeded = 0
        failed = 0
        skipped = 0
        download_downloaded = 0
        download_failed = 0
        download_skipped = 0
        Chef::Log.warn("Start downloading #{@downloaded} fixes (~ #{@dl.to_f.round(2)} GB) to \'#{@dl_target}\' directory.")
        # start = Time.now
        exit_status = Open3.popen3(suma_s) do |stdin, stdout, stderr, wait_thr|
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
            # time_s = duration(Time.now - start)
            print "\rSUCCEEDED: #{succeeded}/#{@downloaded}\tFAILED: #{failed}/#{@failed}\tSKIPPED: #{skipped}/#{@skipped}" # . (Total time: #{time_s})."
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
          wait_thr.value # Process::Status object returned.
        end
        unless exit_status.success?
          raise SumaDownloadError, "Error: Command \"#{suma_s}\" returns above error!"
        end
        Chef::Log.warn("Finish downloading #{succeeded} fixes.")
        @download = download_downloaded
        @failed = download_failed
        @skipped = download_skipped
      end
    end

    class Nim
      include Chef::Mixin::ShellOut

      def initialize
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
          Chef::Log.warn("Done nim define operation \"#{nim_s}\"")
        end
      end

      def perform_customization(lpp_source, clients, async = true)
        async_s = async ? 'yes' : 'no'
        nim_s = "/usr/sbin/nim -o cust -a lpp_source=#{lpp_source} -a accept_licenses=yes -a fixes=update_all -a async=#{async_s} #{clients}"
        Chef::Log.warn("Start updating machine(s) \'#{clients}\' to #{lpp_source}.")
        if async # asynchronous
          so = shell_out(nim_s, timeout: 3000)
          so.stdout.each_line do |line|
            Chef::Log.info("[STDOUT] #{line.chomp}")
          end
          so.stderr.each_line do |line|
            Chef::Log.info("[STDERR] #{line.chomp}")
          end
          if so.error? && so.stdout !~ /Either the software is already at the same level as on the media, or/m
            raise NimCustError, "Error: Command \"#{nim_s}\" returns:\n--- STDERR ---\n#{so.stderr.chomp!}\n--- STDOUT ---\n#{so.stdout.chomp!}\n--------------"
          else
            Chef::Log.warn("Done nim customize operation \"#{nim_s}\"")
          end
        else # synchronous
          do_not_error = false
          exit_status = Open3.popen3(nim_s) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            stdout.each_line do |line|
              if line =~ /^Filesets processed:.*?[0-9]+ of [0-9]+/
                print "\r#{line.chomp}"
              elsif line =~ /^Finished processing all filesets./
                print "\r#{line.chomp}"
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
          Chef::Log.warn("Finish updating #{clients}.")
          unless exit_status.success? || do_not_error
            raise NimCustError, "Error: Command \"#{nim_s}\" returns above error!"
          end
        end
      end
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

    def check_ohai
      # get list of all NIM machines from Ohai
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
    #    The target machine parameter is mandatory
    #    "*" should be specified as target to apply an operation on all
    #        the machines
    #
    #    raise InvalidTargetsProperty in case of error
    #    - target parameter is empty or not present
    #    - connot contact the target machines
    # -----------------------------------------------------------------
    def expand_targets
      selected_machines = []
      # compute list of machines based on targets property
      if property_is_set?(:targets)
        if !targets.empty?
          targets.split(/[,\s]/).each do |machine|
            # expand wildcard
            machine.gsub!(/\*/, '.*?')
            node['nim']['clients'].keys.each do |m|
              selected_machines.concat(m.split) if m =~ /^#{machine}$/
            end
          end
          selected_machines = selected_machines.sort.uniq
        else # empty... target is mandatory
          raise InvalidTargetsProperty, 'Error: no target machine specified'
        end
      else # not set... target is mandatory
        raise InvalidTargetsProperty, 'Error: no target machine specified'
      end
      Chef::Log.info("List of targets expanded to #{selected_machines}")

      if selected_machines.empty?
        raise InvalidTargetsProperty, 'Error: cannot contact any machines'
      end
      selected_machines
    end

    def check_lpp_source_name(lpp_source)
      if node['nim']['lpp_sources'].fetch(lpp_source)
        Chef::Log.debug("Found lpp source #{lpp_source}")
      end
    rescue KeyError
      raise InvalidLppSourceProperty, "Error: cannot find lpp_source \'#{lpp_source}\' from Ohai output"
    end

    def compute_rq_type
      if property_is_set?(:oslevel)
        if oslevel =~ /^([0-9]{4}-[0-9]{2})(|-00|-00-0000)$/
          rq_type = 'TL'
        elsif oslevel =~ /^([0-9]{4}-[0-9]{2}-[0-9]{2})(|-[0-9]{4})$/
          rq_type = 'SP'
        elsif oslevel.empty? || oslevel.casecmp('latest') == 0
          rq_type = 'Latest'
        else
          raise InvalidOsLevelProperty, 'Error: oslevel is not recognized'
        end
      else # default
        rq_type = 'Latest'
      end
      rq_type
    end

    def compute_filter_ml(targets)
      # build machine-oslevel hash
      hash = Hash.new { |h, k| h[k] = node['nim']['clients'].fetch(k, {}).fetch('oslevel', nil) }
      targets.each { |k| hash[k] }
      hash.delete_if { |_k, v| v.nil? || v.empty? }
      Chef::Log.debug("Hash table (machine/oslevel) built #{hash}")

      unless hash.empty?
        # discover FilterML level
        ary = hash.values.collect { |v| v.match(/^([0-9]{4}-[0-9]{2})(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1].delete('-') }
        # find lowest ML
        filter_ml = ary.min
      end

      if filter_ml.nil?
        raise InvalidTargetsProperty, 'Error: cannot discover filter ml based on the list of targets'
      else
        filter_ml.insert(4, '-')
      end
      filter_ml
    end

    def compute_rq_name(rq_type, targets)
      unless property_is_set?(:tmp_dir) && !tmp_dir.to_s.empty?
        tmp_dir = '/usr/sys/inst.images'
      end
      if ::File.directory?(tmp_dir)
        shell_out!("rm -rf #{tmp_dir}/*")
      else
        shell_out!("mkdir -p #{tmp_dir}")
      end

      case rq_type
      when 'Latest'
        # build machine-oslevel hash
        hash = Hash.new { |h, k| h[k] = node['nim']['clients'].fetch(k, {}).fetch('oslevel', nil) }
        targets.each { |k| hash[k] }
        hash.delete_if { |_k, v| v.nil? || v.empty? }
        Chef::Log.debug("Hash table (machine/oslevel) built #{hash}")
        unless hash.empty?
          # discover FilterML level
          ary = hash.values.collect { |v| v.match(/^([0-9]{4}-[0-9]{2})(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1].delete('-') }
          # find highest ML
          metadata_filter_ml = ary.max
          # check ml level of machines
          if ary.min[0..3].to_i < ary.max[0..3].to_i
            Chef::Log.warn("Release level mismatch, only AIX #{ary.max[0]}.#{ary.max[1]} SP/TL will be downloaded")
          end
        end
        if metadata_filter_ml.nil?
          raise InvalidTargetsProperty, 'Error: cannot discover filter ml based on the list of targets'
        else
          metadata_filter_ml.insert(4, '-')
        end
        Chef::Log.info("Found highest ML #{metadata_filter_ml} from client list")

        # suma metadata
        suma = Suma.new(desc, 'Latest', nil, metadata_filter_ml, tmp_dir)
        suma.metadata

        # find latest SP for highest TL
        sps = shell_out("ls #{tmp_dir}/installp/ppc/*.install.tips.html").stdout.split
        sps.collect! do |file|
          file.gsub!('install.tips.html', 'xml')
          text = ::File.open(file).read
          text.match(/^<SP name="([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})">$/)[1].delete('-')
        end
        rq_name = sps.max
        unless rq_name.nil?
          rq_name.insert(4, '-')
          rq_name.insert(7, '-')
          rq_name.insert(10, '-')
        end
        Chef::Log.info("Discover RqName #{rq_name} with metadata suma command")

      when 'TL'
        # pad with 0
        rq_name = "#{oslevel.match(/^([0-9]{4}-[0-9]{2})(|-00|-00-0000)$/)[1]}-00-0000"

      when 'SP'
        if oslevel =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}$/
          rq_name = oslevel
        elsif oslevel =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/
          # suma metadata
          metadata_filter_ml = oslevel.match(/^([0-9]{4}-[0-9]{2})-[0-9]{2}$/)[1]
          suma = Suma.new(desc, 'Latest', nil, metadata_filter_ml, tmp_dir)
          suma.metadata

          # find SP build number
          text = ::File.open("#{tmp_dir}/installp/ppc/#{oslevel}.xml").read
          rq_name = text.match(/^<SP name="([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})">$/)[1]
          Chef::Log.info("Discover RqName #{rq_name} with metadata suma command")
        end
      end
      rq_name
    end

    def compute_lpp_source_name(rq_name)
      if property_is_set?(:location)
        location.chomp!('\/')
        lpp_source = (location.start_with?('/') || location.empty?) ? "#{rq_name}-lpp_source" : location
      else # default
        lpp_source = "#{rq_name}-lpp_source"
      end
      lpp_source
    end

    def compute_dl_target(lpp_source)
      if property_is_set?(:location)
        location.chomp!('\/')
        if location.start_with?('/')
          dl_target = "#{location}/#{lpp_source}"
          unless node['nim']['lpp_sources'].fetch(lpp_source, {}).fetch('location', nil).nil?
            Chef::Log.debug("Found lpp source \'#{lpp_source}\' location")
            unless node['nim']['lpp_sources'][lpp_source]['location'] =~ /^#{dl_target}/
              raise InvalidLocationProperty, 'Error: lpp source location mismatch'
            end
          end
        elsif location.empty? # empty
          dl_target = "/usr/sys/inst.images/#{lpp_source}"
        else # directory
          begin
            dl_target = node['nim']['lpp_sources'].fetch(location).fetch('location')
            Chef::Log.debug("Discover \'#{location}\' lpp source's location: \'#{dl_target}\'")
          rescue KeyError
            raise InvalidLocationProperty, "Error: cannot find lpp_source \'#{location}\' from Ohai output"
          end
        end
      else # default
        dl_target = "/usr/sys/inst.images/#{lpp_source}"
      end
      dl_target
    end

    # this function is used to search a lpp_source resource
    # find_resource("sp","latest") --> search the latest available service pack for your system
    # find_resource("sp","next")   --> search the next available service pack for your system
    # find_resource("tl","latest") --> search the latest available technology level for your system
    # find_resource("tl","next")   --> search the next available technology level for your system
    def find_resource_by_client(type, time, client)
      Chef::Log.debug("nim: finding #{time} #{type}")
      # not performing any test on this shell
      current_oslevel = node['nim']['clients'][client]['oslevel'].split('-')
      # this command should show an outpout like this on
      # 7100-01-01-1210-lpp_source
      # 7100-01-02-1415-lpp_source
      # 7100-03-04-1415-lpp_source
      # 7100-03-05-1514-lpp_source
      aixlevel = current_oslevel[0]
      tllevel = current_oslevel[1]
      splevel = current_oslevel[2]
      lppsource = ''
      if type == 'tl'
        # reading output until I have found the good tl
        node['nim']['lpp_sources'].keys.each do |key|
          a_key = key.split('-')
          if a_key[0] == aixlevel && a_key[1] > tllevel
            lppsource = key
            break if time == 'next'
          end
        end
      elsif type == 'sp'
        # reading output until I have found the good sp
        node['nim']['lpp_sources'].keys.each do |key|
          a_key = key.split('-')
          if a_key[0] == aixlevel && a_key[1] == tllevel && a_key[2] > splevel
            lppsource = key
            break if time == 'next'
          end
        end
      end
      if lppsource.empty?
        # setting lpp_source to current oslevel
        lppsource = current_oslevel[0] + '-' + current_oslevel[1] + '-' + current_oslevel[2] + '-' + current_oslevel[3] + '-lpp_source'
        Chef::Log.debug("nim: server already to the #{time} #{type}, or no lpp_source were found, #{lppsource} will be utilized")
      else
        Chef::Log.debug("nim: we found the #{time} lpp_source, #{lppsource} will be utilized")
      end
      lppsource
    end
  end
end
