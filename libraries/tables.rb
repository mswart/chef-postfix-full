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
  class Table
    @@types = {}

    def self.register(cls, types)
      types.each do |type|
        @@types[type] = cls
      end
    end

    def self.new_as_table_type(node, name, params)
      unless @@types.include? params['_type']
        msg = "postfix table: unknown table type: #{params['_type']}"
        Chef::Log.fatal msg
        raise msg
      end
      @@types[params['_type']].new node, name, params
    end

    def self.split_params_and_data(options)
      data = {}
      params = {}
      options.each do |option, value|
        if option.chars.first != '_' # normal content key
          data[option] = value
        else
          ( option[0..1] != '__' ? params : data)[option[1..-1]] = value
        end
      end
      params.each do |param, option|
        if param =~ /(.+)_from_file/
          data[$1] = File.open(option).read.rstrip
        end
      end
      [ params, data ]
    end



    attr_reader :node, :name, :data

    def initialize(node, name, params)
      @node = node
      @name = name
      @params, @data = self.class.split_params_and_data(params)
    end

    def generate_resources
      raise 'generate_resources not implemented'
    end

    def default_params
      {
        'user' => 'root',
        'group' => 0,
        'mode' => 00644,
        'file' => ::File.join(node['postfix']['base_dir'], 'tables', name)
      }
    end

    def params
      default_params.merge @params
    end

    def identifier
      prefix = params['proxy'] ? 'proxy:' : ''
      "#{prefix}#{params['type']}:#{params['file']}"
    end
  end


  class ConfigTable < Table
    register self, %w(ldap memcache mysql pgsql sqlite tcp)

    def generate_resources(recipe)
      params = self.params
      config = Postfix::MainConfig.new data

      recipe.file params['file'] do
        content config.content
        user params['user']
        group params['group']
        mode params['mode']
      end
    end
  end


  class HashTable < Table
    register self, %w(hash)

    def generate_config_content()
      lines = []
      data.sort.each do |option, value|
        next if value.nil?
        lines << "#{option} #{value}"
      end
      lines << ''
      lines.join "\n"
    end

    def generate_resources(recipe)
      params = self.params
      content = generate_config_content
      execute_name = "postmap-#{name}"

      recipe.execute execute_name do
        command "postmap #{params['file']}"
        user params['user']
        group params['group']
        action :nothing
      end

      recipe.file params['file'] do
        content content
        user params['user']
        group params['group']
        mode params['mode']
        notifies :run, "execute[#{execute_name}]"
      end
    end
  end

  class OrderTable < Table
    register self, %w(cidr regexp pcre)

    def generate_config_content()
      unless params['format'] == 'pairs_sorted_by_key'
        raise "unknown table content format #{params['format']}"
      end
      lines = data.sort.map { |option, value| "#{option} #{value}" }
      lines << ''
      lines.join "\n"
    end

    def generate_resources(recipe)
      params = self.params
      content = generate_config_content

      recipe.file params['file'] do
        content content
        user params['user']
        group params['group']
        mode params['mode']
      end
    end
  end
end
