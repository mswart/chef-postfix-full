#
# Cookbook Name:: postfix-full
# Recipe:: default
#
# Author:: Malte Swart (<chef@malteswart.de>)
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

package 'postfix'

service 'postfix' do
  supports :status => true, :restart => true, :reload => true
  action :enable
end

postfix_tables = Postfix::TableFetcher.new(node).fetch

# generate main.cf
main_cf = Postfix::MainConfig.new(node['postfix']['main'].to_hash)
main_cf.register_tables postfix_tables

# write main.cf
file ::File.join(node['postfix']['base_dir'], 'main.cf') do
  content main_cf.content
  user 'root'
  group 0
  mode 00644
  notifies :reload, "service[postfix]"
end

# generate master.cf
file ::File.join(node['postfix']['base_dir'], 'master.cf') do
  content Postfix::MasterConfig.new(node['postfix']['master']).content
  user 'root'
  group 0
  mode 00644
  notifies :restart, "service[postfix]"
end

# generate postfix tables
directory ::File.join(node['postfix']['base_dir'], 'tables') do
  owner "root"
  group "root"
  mode 00755
  action :create
end

postfix_tables.each do |table|
  table.generate_resources self
end

used_table_types = main_cf.used_table_types
used_table_types |= postfix_tables.map { |t| t.params['type'] }.flatten
used_table_types.uniq.each do |table_type|
  pkg = node['postfix']['table-packages'][table_type]
  next unless pkg
  package pkg
end

# start service
service 'postfix' do
  action :start
end
