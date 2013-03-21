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
  def self.generate_config_file(data)
    lines = []
    data.to_hash.sort.each do |option, value|
      next if value.nil?
      value = 'yes' if value == true
      value = 'no' if value == false
      lines << "#{option} = #{value}"
    end
    lines << ''
    lines.join "\n"
  end

  def self.chef_error msg
    Chef::Log.fatal msg
    raise msg
  end
end


class Chef::Node
  def generate_postfix_main_cf
    return nil if self['postfix']['main'].nil?
    Postfix.generate_config_file self['postfix']['main']
  end

  def generate_postfix_master_cf
    return nil if self['postfix']['master'].nil?
    lines = '''# MANAGED BY CHEF - DO NOT EDIT
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
'''.split('\n')
    self['postfix']['master'].to_hash.sort.each do |name, service|
      next if service.nil?
      if /^(inet|unix|fifo|pass):(.+)$/ =~ name
        type = $1
        name = $2
      else
        type = 'unix'
      end
      service[:command] ||= name
      # service name + type
      line = name.ljust(9) + ' ' + type.to_s.ljust(5)
      # options
      [ :private, :unpriv, :chroot, :wakeup, :maxproc ].each do |option|
        line += ' ' + map_value(service[option], 7)
      end
      # command
      line += ' ' + service[:command]
      lines << line
      # 9. args
      lines += convert_command_args(service[:args])
    end
    lines << ''
    lines.join "\n"
  end

  def get_postfix_tables
    tables = self['postfix']['tables'].to_hash
    tables.inject([]) do |result, (name, options)|
      # resolving parent references
      while options['_parent']
        unless tables.include? options['_parent']
          Postfix.chef_error "postfix-table: could not find parent table #{options['_parent']}"
        end
        options = Chef::Mixin::DeepMerge.merge(
          tables[options['_parent']].reject { |k, v| k == '_abstract'},
          options.reject { |k, v| k == '_parent'}
        )
      end
      # skip if table is abstract
      next result if options['_abstract']
      # create table object from params
      result << Postfix::Table.new_as_table_type(self, name, options)
    end
  end

  private
  def map_value(value, size)
    { false => 'n', true => 'y', nil => '-' }.fetch(value, value).to_s.ljust(size)
  end

  def convert_command_args(args)
    return [] if args.nil?
    if args.kind_of? String
      [ args ]
    else
      args
    end.map { |line| '  ' + line }
  end
end
