name              'postfix-full'
maintainer        'Malte Swart'
maintainer_email  'chef@malteswart.de'
license           'Apache 2.0'
description       'Full installation and management about a postfix instance'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           '0.1.2'

%w{ ubuntu }.each do |os|
  supports os
end

conflicts 'postfix'
