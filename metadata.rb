name 'elrond'
maintainer 'Mr Staker'
maintainer_email 'hello@mr.staker.ltd'
version '1.0.0'
source_url 'https://github.com/mr-staker/elrond-cookbook'
issues_url 'https://github.com/mr-staker/elrond-cookbook/issues'
chef_version '>= 16'
%w[centos debian oracle redhat ubuntu].each do |os|
  supports os
end
license 'MIT'
description 'Installs and configures Elrond Network nodes'

gem 'inifile', '~> 3.0.0'
gem 'deep_merge', '~> 1.2.1'
gem 'toml', '~> 0.2.0'
gem 'vault', '~> 0.16.0'
