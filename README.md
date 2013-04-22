chef-postfix-full
=================

[![Code Climate](https://codeclimate.com/github/mswart/chef-postfix-full.png)](https://codeclimate.com/github/mswart/chef-postfix-full) [![Build Status](https://travis-ci.org/mswart/chef-postfix-full.png)](https://travis-ci.org/mswart/chef-postfix-full)


Description
-----------

Another Postfix cookbook for chef. Against others (e.g. the [opscode/postfix](https://github.com/opscode-cookbooks/postfix)) it tries to abstract all configuration possibilities of Postfix to chef with attributes and data bags.

The goal is that the cookbook does not limit your usage of Postfix in any ways.

Therefore it is not designed for people who want a fast way to a working Postfix instance. The default attributes are limited to a minimum, all other configuration is up to you to adjust Postfix to your needs.

**Info**: Currently multi-instances are not covered. I have some ideas about that but no need.
Talk to me if you need them.


Requirements
------------

The cookbook requires:

* **ruby 1.8.7+**: Ruby 1.8.7 is currently full supported. But in a few month (also end of life of ruby 1.8), is will be dropped and **ruby 1.9.3** is needed.
* **chef 10.18+**: The cookbook is design to run under chef 10 and chef 11. Therefore I recommends chef 10.18+ because it is a preparing and migration release. Chef server and chef solo are supported. But some features may not available with chef solo.
* (**Ubuntu**): The cookbook is tested on Ubuntu 12.04. Other distributions like Debian may work also. I appreciate feedback about status and errors on other distributions or versions.

This cookbook conflicts with the Opscode postfix cookbook because it uses the same attribute name space `node['postfix']`. But I can think of situations where it will work without problems. Talk to me if you have this circumstances and want the conflicts metadata to be removed.


Recipes
-------

There are only two recipes:

* `default`: installs Postfix and manages `main.cf`, `master.cf` and lookup tables
* `dovecot`: setup some default values to use dovecot as authentication provider and for mail delivery. (**planned**)


main.cf
-------

The `main.cf` is managed via `node['postfix']['main']`.

Use option name as key inside this hash. For the value multiple types are supported:

* `true`, `false`: Use for boolean values, they result in `yes` and `no`.
* `Integer`: Direct mapping of integers.
* `String`: The important type use this for all options. The string is pasted into the file without modification. So substitutions like `$base_directory` are possible.
* `''`: Special case of the String type. Designed to clear a default value for Postfix.
* `nil`: ignore this option and exclude it from `main.cf`. So the Postfix default is used.

See [same main.cf example configurations](#basic-changes-and-hash-tables)


master.cf
---------

Every service of `master.cf` has an entry inside the hash `node['postfix']['master']`.

The service type and name is the key - separated by a colon. If service type is unix, the `unix:` prefix may be omitted. The service should be `nil` to be ignored or a hash. The hash supports the following attributes:

* `command` (`service name`): The program which should be started.
* `args` (`nil`): Additional arguments for the command call. Could be a string or a list of strings (entries are separated with new lines in `master.cf` but no difference to separation entries with a blank). Use `nil` to pass no additional arguments.
* `private` (`y`): Whether or not access is restricted to the mail system.
* `unpriv` (`y`): Whether the service runs with root privileges or as the owner of the Postfix system.
* `chroot` (`y`): Whether or not the service runs chrooted to the mail queue directory.
* `wakeup` (`0`): Automatically wake up the named service after the specified number of seconds.
* `maxproc` (`$default_process_limit`): The maximum number of processes that may execute this service simultaneously.

Use `nil` or do not set option to use the default value. Use `false` and `true` for `y` and `n`.

See the `master(5)` man page for a complete documentation and [an example definition on other services](#additional-services).

**Planned**: Definition to define services inside other cookbooks.


Look up tables
--------------

The cookbook can manage lookup-tables for you. It can create the configuration files for ldap or mysql. Basic tables like hash tables can be filled with content from attributes (data_bag support planed).

The tables are defined inside the hash `node['postfix']['tables']`.

Every table has a name (internal usage and per defined as file name) as key and a hash as value with its configuration.

The hash has two types of entries:

- **configuration entry**: key-value pair to define options of this table for the cookbook. Every key must start with exactly one `_`.
- **content entry**: Key->value pair to define the content of the table. If the key starts with `_`, the key must be prefixed with additional `_`.

The following configuration entries are specified:

* `_type`: defines the type of the table, see the following subsection for the list and description of the supported tables. The option is required, but can be inhered from parent tables (see _parent).
* `_parent` (`nil`): name of table from which options should be inherit (configuration and content entries). There is no nesting limit but also no loop protection.
* `_abstract` (`nil`): set this to `true` to exclude this resource from chef management. This table can therefore only used as parent table. The `_abstract` option is removed after the inheritance. You have to reset it in the subtable if you what the subtable to be abstract, too.
* `_file` (`$basedir/tables/$table_name`): File name to put the table content or the table configuration (depends on table type)
* `_user` (`root`): User name or id for the files of the table
* `_group` (`0`): Group name or id for the files of the table
* `_mode` (`00644`): Access mode for the files of the table
* `_`$key`_from_file`: The value for content entry $key is set to the content of the given file name.

The following options provides shortcuts to use the table for a Postfix option. The table is registered with it identifier (type + path to file):

* `_set` (`nil`): name or list of names of Postfix options to use only this table. The value for this option in `node['postfix']['main']` will **be overwritten**. Two table must not have the same Postfix option name (only one option will be used).
* `_add` (`nil`): Shortcut to add this table to previously defined values (main value or other table). The value for this option in `node['postfix']['main']` will **not be overwritten**.

  Use a hash as option. Every key should be a name of a `main.cf` configuration option. The value should be a priority. The lowest value will be the first one in the line. The main.cf value has the priority 0. The string as value is a shortcut for `{ $value => nil }` - append option to previous values.

  An example:

  ```ruby
    {
      postfix: {
        main: {
          virtual_alias_maps: 'hash:top_secret'
        },
        tables: {
          fast_table: {
            _type: 'regexp',
            _add: { alias_maps: nil, virtual_alias_maps: -1 }
          },
          low_priority_table: {
            _type: 'ldap',
            _add: { virtual_alias_maps: 3 }
          }
        }
      }
    }
  ```

  will creates the following main.cf options:


  ```
  alias_maps = regexp:/etc/postfix/tables/fast_table
  virtual_alias_maps = regexp:/etc/postfix/tables/fast_table hash:top_secret ldap:/etc/postfix/tables/low_priority_table
  ```
* `_proxy` (false): Set this to true to query the table thought the Postfix proxy server. See `postmap(8)` for more information.

The content entry format depends on the table type.

[An advances table example with a external service and table inheritancee](#advanced-table-usage)


### TableType: hash

Use lookup key as content entry key and result as value. The cookbook call postmap automatically.


### Config tables: ldap, memcache, mysql, pgsql, sqlite, tcp

These tables have all a `main.cf` like configuration file. This file can be created by chef. Set the configuration values like `main.cf` options.

The cookbooks does not ensures that this table type is supported by Postfix. On Debian based distributions additional packages must be installed.


### Tables with ordering: cidr, regexp, pcre

The behavior of the cidr, regexp and pcre table depends on the ordering of the content.

The `_format` configuration options defines how the order is created. The following options are supported:

* `pair_sorted_by_key`: The key->value pairs are sorted by key. Key and value are separated by a blank.

Other formats are planed.


Examples
--------

All attributes are written as 1.9+ ruby hashes - minimal overhead.

### Basic changes and hash tables:

```ruby
{
  postfix: {
    main: {
      # the it explicit because it is a important option
      mydomain: 'cookbooks.example',

      # we needs to support bigger attachments:
      message_size_limit: 25600000,

      # some sasl configuration for smtp client:
      smtp_sasl_auth_enable: true,
      smtp_sender_dependent_authentication: true,

      smtp_sasl_password_maps: 'hash:/etc/postfix/tables/auths', # not managed by chef
      smtp_sasl_security_options: 'noanonymous',
      smtp_sasl_mechanism_filter: '!gssapi, !ntlm, plain, login',
    },
    tables: {
      relayhosts: {
        _type: 'hash',
        _set: 'sender_dependent_relayhost_maps',
        'chef@cookbooks.test' => '[192.0.2.32]',
        '@cookbooks.test' => 'mail37.mails.example',
      }
    }
  }
}
```

### Additional services

```ruby
{
  postfix: {
    master: {
      'inet:submission' => {
        private: false,
        chroot: false,
        command: 'smtpd',
        args: [
          '-o smtpd_sender_login_maps=ldap:/etc/postfix/tables/submission-sender-login-map',
          '-o smtpd_recipient_restrictions=reject_sender_login_mismatch,permit_sasl_authenticated,permit_tls_clientcerts,reject',
        ],
      },
      mailman: {
        unprivate: false,
        chroot: false,
        command: 'pipe',
        args: [
          'flags=FR',
          'user=list',
          'argv=/usr/lib/mailman/bin/postfix-to-mailman.py ${nexthop} ${user}',
        ],
      },
    }
  }
}
```

### Advanced table usage

```ruby
{
  postfix: {
    tables: {
      ldap: {
        _abstract: true,
        _type: 'ldap',
        _proxy: true,
        version: 3,
        server_host: 'ldap.cookbooks.example',
        bind: true,
        bind_dn: 'cn=mail,ou=system,dc=cookbooks,dc=example',
        _bind_pw_from_file: '/etc/postfix/ldap.password',
        search_base: 'ou=mail,dc=cookbooks,dc=example',
        start_tls: true,
        tls_ca_cert_path: '/etc/ssl/certs',
        tls_cert: '/etc/postfix/ssl/mail.cookbooks.example_chain.pem',
        tls_key: '/etc/postfix/ssl/mail.cookbooks.example_key.pem',
        tls_require_cert: true,
      },
      aliases: {
        _parent: 'ldap',
        _add: 'virtual_alias_maps',
        query_filter: '(|(mailAliases=%s)(&(mailUser=%u)(mailDomain=%d)))',
        result_attribute: 'mailDestination',
        domain: 'cookbooks.example, chef.example',
      },
      sender_login_map: {
        _parent: 'ldap',
        _set: 'smtpd_sender_login_maps',
        search_base: 'ou=users,dc=cookbooks,dc=example',
        query_filter: '(|(mail=%s)(mailAliases=%s)(mailAccounts=%s)(mailAccount=%s)(mailAdditionalSender=%s))',
        result_attribute: 'mailAccount',
      },
      transport: {
        _type: 'hash',
        _set: 'transport_maps',
        'lists.cookbooks,example' => 'mailman:',
      },
    }
  },
}
```


Contributing
------------

The cookbook is developed on [github](https://github.com). To report bugs [create an issue](https://github.com/mswart/chef-postfix-full/issues) or open a pull request if you know what needs to be changed.

Feel free to contact me (<chef@malteswart.de> or mswart on freenode) if you have detailed questions about the cookbook. I am interested in your opinion, wishes and use cases.


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
