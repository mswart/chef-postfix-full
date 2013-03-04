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
    return nil if self['postfix'].nil?
    lines = []
    self['postfix'].to_hash.sort.each do |option, value|
      next if value.nil?
      lines << "#{option} = #{value.to_s}"
    end
    lines << ''
    lines.join "\n"
  end
end
