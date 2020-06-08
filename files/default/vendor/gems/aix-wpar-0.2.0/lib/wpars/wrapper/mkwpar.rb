require 'wpars/wrapper/constants'

module WPAR
  module Wrapper
    include Constants
    class MkWpar

      def self.create(options = {})
        cmd = build_mkwpar_command(options)
        puts "debug: #{cmd}" unless options[:debug].nil?
        External.cmd(cmd: cmd, live_stream: options[:live_stream])
      end

      private
      def self.build_mkwpar_command(options = {})
        wpar = options[:wpar]
        cmd = "#{options[:command]} #{Constants::MKWPAR} -s -n #{wpar.name}"

        if options[:start] == "yes"
          cmd += " -a"
        end

        if wpar.general.auto == "yes"
          cmd += " -A"
        end

        unless (wpar.general.hostname.nil? or wpar.general.hostname.empty?)
          cmd += " -h #{wpar.general.hostname}"
        end

        unless options[:backupimage].nil?
          cmd += " -B #{options[:backupimage]}"
        end

        unless options[:rootvg].nil?
          cmd += " -D rootvg=yes devname=#{options[:rootvg]}"
        end

        unless options[:wparvg].nil?
          cmd += " -g #{options[:wparvg]}"
        end

        # NETWORK section
        wpar.networks.each do |net|
          if net.empty?
            next
          end

          cmd += " -N"

          unless net.address.nil?
            cmd += " address=#{net.address}"
          end

          unless net.interface.nil?
            cmd += " interface=#{net.interface}"
          end

          unless net.mask_prefix.nil?
            cmd += " netmask=#{net.mask_prefix}"
          end

          unless net.broadcast.nil?
            cmd += " broadcast=#{net.interface}"
          end
        end

        unless wpar.resource_control.empty?
          cmd += " -R"
          unless wpar.resource_control.cpu.nil?
            cmd += " CPU=#{wpar.resource_control.cpu}"
          end
          unless wpar.resource_control.shares_cpu.nil?
            cmd += " shares_CPU=#{wpar.resource_control.shares_cpu}"
          end
          unless wpar.resource_control.memory.nil?
            cmd += " memory=#{wpar.resource_control.memory}"
          end
          unless wpar.resource_control.shares_memory.nil?
            cmd += " shares_memory=#{wpar.resource_control.shares_memory}"
          end
          unless wpar.resource_control.rset.nil?
            cmd += " rset=#{wpar.resource_control.rset}"
          end
        end

        cmd
      end
    end
  end
end
