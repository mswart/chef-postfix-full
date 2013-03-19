chef-postfix-full
=================

**This cookbook is currently under development and designing! Because the README is written before
the feature is implemented, some points could be missing.**


Description
-----------

Another postfix cookbook for chef. Against others (e.g. the [opscode/postfix](https://github.com/opscode-cookbooks/postfix)) it tries to abstract
all configuration possibilities of postfix to chef with attributes and data bags.

The goal is that the cookbook does not limit your usage of postfix in any ways.

Therefore it is not designed for people who want a fast way to a working postfix instance. The default
attributes are limited to a minimum, all other configuration is up to you to adjust postfix to your
needs.

**Info**: Currently multi-instances are not covered. I have some ideas about that but no need.
Talk to me if you need them.


Recipes
-------

There are only two recipes:

* `default`: installs postfix and manages `main.cf`, `master.cf` and lookup tables
* `dovecot`: setup some default values to use dovecot as authentification provider and for mail
   delivery.


main.cf
-------

The `main.cf` is managed via `node['postfix']['main']`.

Use option name as key inside this hash. For the value multiple types are supported:

* `true`, `false`: Use for boolean values, they result in `yes` and `no`.
* `Integer`: Direct mapping of integers.
* `String`: The important type use this for all options. The string is pasted into the file without
   modification. So substitutions like `$base_directory` are possible.
* `''`: Speical case of the String type. Designed to clear a default value for postfix.
* `nil`: ignore this option and exclude it from `main.cf`. So the postfix default is used.


master.cf
---------

Every service of `master.cf` has an entry inside the hash `node['postfix']['master']`.

The service type and name is the key - separated by a colon. If service type is unix, the `unix:`
prefix may be omitted. The service should be `nil` to be ignored or a hash. The hash supports
the following attributes:

* `command` (`service name`): The program which should be started.
* `args` (`nil`): Additional arguments for the command call. Could be a string or a list of strings
  (entries are separated with new lines in `master.cf` but no difference to separation entries with
  a blank). Use `nil` to pass no additional arguments.
* `private` (`y`): Whether or not access is restricted to the mail system.
* `unpriv` (`y`): Whether the service runs with root privileges or as the owner of the Postfix
  system.
* `chroot` (`y`): Whether or not the service runs chrooted to the mail queue directory.
* `wakeup` (`0`): Automatically wake up the named service after the specified number of seconds.
* `maxproc` (`$default_process_limit`): The maximum number of processes that may execute this
  service simultaneously.

Use `nil` or do not set option to use the default value. Use `false` and `true` for `y` and `n`.

See the `master(5)` man page for a complete documentation.

**Planned**: Definition to define services inside other cookbooks.


lookup-tables
-------------

The cookbook can manage lookup-tables for you. It can create the configuration files for ldap or
mysql. Basic tables like hash tables can be filled with content from attributes or data_bags.

**ToDo**: Define attribute interface for lookup tables. Should support inheritance of lookup
tables. Primary used to create a lot of similar `ldap` or `mysql` tables.


License and Author
------------------

Author:: Malte Swart (<chef@malteswart.de>)
Copyright:: 2013, Malte Swart

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
