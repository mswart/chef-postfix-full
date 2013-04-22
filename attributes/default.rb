#
# Cookbook Name:: postfix
# Attributes:: default
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

default['postfix']['base_dir'] = '/etc/postfix'

default['postfix']['main'] = {}
default['postfix']['main']['myhostname'] = node['fqdn']
default['postfix']['main']['mydomain'] = node['domain']
default['postfix']['main']['myorigin'] = '/etc/mailname'


default['postfix']['tables'] = {}

%w{cdb ldap mysql prec pgsql}.each do |type|
  default['postfix']['table-packages'][type] = "postfix-#{type}"
end


# default['postfix']['master'] for master.cf
default['postfix']['master'] = {}
default['postfix']['master']['inet:smtp'  ] = { :private => false, :command => 'smtpd' }
default['postfix']['master']['fifo:pickup'] = { :private => false, :wakeup => 60, :maxproc => 1 }
default['postfix']['master']['cleanup'    ] = { :private => false, :maxproc => 0 }
default['postfix']['master']['fifo:qmgr'  ] = { :private => false, :chroot => false, :wakeup => 300, :maxproc => 1 }
default['postfix']['master']['tlsmgr'     ] = { :wakeup => '1000?', :maxproc => 1 }
default['postfix']['master']['rewrite'    ] = { :command => 'trivial-rewrite' }
default['postfix']['master']['bounce'     ] = { :maxproc => 0 }
default['postfix']['master']['defer'      ] = { :maxproc => 0, :command => 'bounce' }
default['postfix']['master']['trace'      ] = { :maxproc => 0, :command => 'bounce' }
default['postfix']['master']['verify'     ] = { :maxproc => 1 }
default['postfix']['master']['flush'      ] = { :wakeup => '1000?', :maxproc => 0 }
default['postfix']['master']['proxymap'   ] = { :chroot => false }
default['postfix']['master']['proxywrite' ] = { :chroot => false, :command => 'proxymap' }
default['postfix']['master']['smtp'       ] = {}
default['postfix']['master']['relay'      ] = { :command =>  'smtp' }
default['postfix']['master']['showq'      ] = { :private =>  false }
default['postfix']['master']['error'      ] = {}
default['postfix']['master']['retry'      ] = { :command => 'error' }
default['postfix']['master']['discard'    ] = {}
default['postfix']['master']['local'      ] = { :unpriv => false, :chroot => false }
default['postfix']['master']['virtual'    ] = { :unpriv => false, :chroot => false }
default['postfix']['master']['lmtp'       ] = {}
default['postfix']['master']['anvil'      ] = { :maxproc => 1 }
default['postfix']['master']['scache'     ] = { :maxproc => 1 }
