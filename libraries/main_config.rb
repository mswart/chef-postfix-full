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
  class MainConfig
    attr_reader :options

    def initialize(options)
      @options = options
      @options_to_merge = {}
    end

    def content
      merge_options
      lines = []
      options.sort.each do |option, value|
        next if value.nil?
        value = 'yes' if value == true
        value = 'no' if value == false
        lines << "#{option} = #{value}"
      end
      lines << ''
      lines.join "\n"
    end

    def set_option(name_or_names, value)
      unless name_or_names.respond_to? :each
        name_or_names = [ name_or_names ]
      end
      name_or_names.each do |name|
        options[name] = value
      end
    end

    def add_option(options, value)
      if options.is_a? String
        options = { options => nil }
      end
      options.each do |option, preference|
        @options_to_merge[option] ||= []
        @options_to_merge[option] << [preference, value]
      end
    end

    def register_tables(tables)
      tables.each do |table|
        params = table.params
        if params['set']
          set_option params['set'], table.identifier
        end
        if params['add']
          add_option params['add'], table.identifier
        end
      end
    end

    def used_table_types
      tables = []
      @options.each do |option, value|
        value.to_s.split(' ').each do |v|
          if v =~ /^(\w+):.+$/
            tables << $1
          end
        end
      end
      tables
    end


    private

    def merge_options
      @options_to_merge.each do |option, values|
        if options[option]
          values << [ 0, options[option] ]
        end
        options[option] = values.sort.map { |p, v| v }.join(" ")
      end
      @options_to_merge = {}
    end
  end
end
