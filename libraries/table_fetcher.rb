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
  class TableFetcher
    attr_reader :node, :table_data

    def initialize(node)
      @node = node
      @table_data = node['postfix']['tables'].to_hash
    end

    def fetch
      tables = []
      table_data.each do |name, options|
        options = resolve_inheritance options.to_hash
        # skip abstract tables, they are only for inheritance
        next if options['_abstract']
        # create table object from options, class is chooses from _type option
        tables << Postfix::Table.new_as_table_type(node, name, options)
      end
      tables
    end


    private

    def resolve_inheritance(options)
      return options.dup unless options['_parent']
      unless table_data.include? options['_parent']
        msg = "postfix-table: could not find parent table #{options['_parent']}"
        Chef::Log.fatal msg
        raise msg
      end
      parent_options = resolve_inheritance table_data[options['_parent']]
      # remove _abstract option, because children do not inherit it:
      parent_options.delete '_abstract'
      # remove _parent option because parent data are fetched:
      options.delete '_parent'
      # use chef's deep merge algorithm to merge the data:
      Chef::Mixin::DeepMerge.merge parent_options, options
    end
  end
end
