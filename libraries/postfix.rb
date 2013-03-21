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

class Chef::Node
  def generate_postfix_main_cf
    return nil if self['postfix']['main'].nil?
    lines = []
    self['postfix']['main'].to_hash.sort.each do |option, value|
      next if value.nil?
      value = 'yes' if value == true
      value = 'no' if value == false
      lines << "#{option} = #{value}"
    end
    lines << ''
    lines.join "\n"
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
    def map_value(value, size)
      { false => 'n', true => 'y', nil => '-' }.fetch(value, value).to_s.ljust(size)
    end
    self['postfix']['master'].to_hash.sort.each do |name, service|
      next if service.nil?
      if /^(inet|unix|fifo|pass):(.+)$/ =~ name
        type = $1
        name = $2
      else
        type = 'unix'
      end
      service[:command] ||= name
      # 1. service name
      line = name.ljust(9)
      # 2. type
      line += ' ' + type.to_s.ljust(5)
      # 3. private
      line += ' ' + map_value(service[:private], 7)
      # 4. unpriv
      line += ' ' + map_value(service[:unpriv], 7)
      # 5. chroot
      line += ' ' + map_value(service[:chroot], 7)
      # 6. wakeup
      line += ' ' + map_value(service[:wakeup], 7)
      # 7. maxproc
      line += ' ' + map_value(service[:maxproc], 7)
      # 8. command + args
      line += ' ' + service[:command]
      lines << line
      # 9. args
      unless service[:args].nil?
        lines += if service[:args].kind_of? String
          [ service[:args] ]
        else
          service[:args]
        end.map { |l| '  ' + l }
      end
    end
    lines << ''
    lines.join "\n"
  end

  def get_postfix_tables
    table_data = self['postfix']['tables'].to_hash
    tables = {}
    table_data.each do |name, options|
      # resolving parent references
      while not options['_parent'].nil?
        parent_options = table_data[options['_parent']]
        unless parent_options
          msg = "postfix-table: could not find parent table #{options['_parent']}"
          Chef::Log.fatal msg
          raise msg
        end
        parent_options = parent_options.reject { |k, v| k == '_abstract'}
        options = Chef::Mixin::DeepMerge.merge(parent_options, options.reject { |k, v| k == '_parent'})
      end
      # spliting data and params
      data = {}
      params = {}
      options.each do |option, value|
        if option[0] != 95 # normal content key
          data[option] = value
        else
          ( option[1] != 95 ? params : data)[option[1..-1]] = value
        end
      end
      # skip if table is abstract
      next if params['abstract'] == true
      # create table object from params
      tables[name] = Postfix::Table.new_as_table_type name, params, data
    end
    tables
  end
end
