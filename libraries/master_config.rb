#
# Author:: Malte Swart (<chef@malteswart.de>)
# Cookbook Name:: postfix-full
#
# Copyright 2013, Malte Swart
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

module Postfix
  class MasterConfig
    attr_reader :services

    def initialize(services)
      @services = services
    end

    def content
      lines = config_header.split('\n')
      services.sort.each do |name, service|
        next if service.nil?
        if /^(inet|unix|fifo|pass):(.+)$/ =~ name
          type = $1
          name = $2
        else
          type = 'unix'
        end
        lines += generate_service_config name, type, service
      end
      lines << ''
      lines.join "\n"
    end


    private

    def config_header
'''# MANAGED BY CHEF - DO NOT EDIT
#
# Postfix master process configuration file.  For details on the format
# of the file, see the master(5) manual page (command: "man 5 master").
#
# Do not forget to execute "postfix reload" after editing this file.
#
# ==========================================================================
# service type  private unpriv  chroot  wakeup  maxproc command + args
#               (yes)   (yes)   (yes)   (never) (0)
# ==========================================================================
'''
    end

    def map_value(value)
      { false => 'n', true => 'y', nil => '-' }.fetch(value, value)
    end

    def convert_command_args(args)
      return [] if args.nil?
      if args.kind_of? String
        [ args ]
      else
        args
      end.map { |line| '  ' + line }
    end

    def align_table_column(columns)
      line = ''
      width = 0
      columns.each do |data, size|
        line = (line + data.to_s).ljust(width + size) + ' '
        width += size + 1
      end
      line
    end

    def generate_service_config(name, type, options)
      columns = []
      columns << [ name, 9 ]
      columns << [ type, 5 ]
      %w(private unpriv chroot wakeup maxproc).each do |option|
        columns << [ map_value(options[option]), 7 ]
      end
      columns << [ options[:command] || name, 1 ]
      # 9. args
      [ align_table_column(columns) ] + convert_command_args(options[:args])
    end
  end
end
