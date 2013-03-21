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

    def self.new_as_table_type(name, params, data)
      unless @@types.include? params['type']
        msg = "postfix table: unknown table type: #{params['type']}"
        Chef::Log.fatal msg
        raise msg
      end
      @@types[params['type']].new name, params, data
    end

    attr_reader :name, :params, :data

    def initialize(name, params, data)
      @name = name
      @params = params
      @data = data
    end

    def generate_resources()
      raise 'generate_resources not implemented'
    end
  end


  class ConfigTable < Table
    register self, %w(ldap memcache mysql pgsql sqlite tcp)

    def generate_config_content()
      lines = []
      data.sort.each do |option, value|
        next if value.nil?
        value = 'yes' if value == true
        value = 'no' if value == false
        lines << "#{option} = #{value}"
      end
      lines << ''
      lines.join "\n"
    end

    def generate_resources(recipe)
      default_params = {
        'user' => 'root',
        'group' => 0,
        'mode' => 00644,
        'file' => ::File.join(recipe.node['postfix']['base_dir'], 'tables', name)
      }
      params = default_params.merge @params
      content = generate_config_content

      recipe.file params['file'] do
        content content
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
      default_params = {
        'user' => 'root',
        'group' => 0,
        'mode' => 00644,
        'file' => ::File.join(recipe.node['postfix']['base_dir'], 'tables', name)
      }
      params = default_params.merge @params
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
end
