name 'elrond'
maintainer 'Mr Staker'
maintainer_email 'hello@mr.staker.ltd'
version '1.0.0'
source_url 'https://github.com/mr-staker/elrond-cookbook'
issues_url 'https://github.com/mr-staker/elrond-cookbook/issues'
chef_version '>= 12.5'
%w[amazon centos fedora debian oracle redhat ubuntu].each do |os|
  supports os
end
license 'MIT'
description 'Installs and configures Elrond Network nodes'
depends 'ultimate_config_cookbook', '~> 0.1.7'
