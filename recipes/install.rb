# runs through repository bootstrap - past this point, the actual
# management is handed over to the staker-repo package which deals with the
# repository configuration itself and the signing key rotation

apt_package %w[gnupg2 apt-transport-https] do
  only_if { platform_family? 'debian' }
end

apt_repository 'staker' do
  key 'https://keybase.io/saltwaterc/pgp_keys.asc?fingerprint='\
    "#{node['staker']['key']['fingerprint']}"

  uri 'https://deb.staker.ltd'
  distribution 'stable'
  components %w[main]

  only_if { platform_family? 'debian' }
  not_if { ::File.exist? '/etc/apt/sources.list.d/staker.list' }
end

yum_repository 'staker' do
  description 'Mr Staker rpm repository'
  baseurl 'https://rpm.staker.ltd/$basearch'
  gpgkey 'https://keybase.io/saltwaterc/pgp_keys.asc?fingerprint='\
    "#{node['staker']['key']['fingerprint']}"
  gpgcheck true
  repo_gpgcheck true

  only_if { platform_family? 'rhel' }
  not_if { ::File.exist? '/etc/yum.repos.d/staker.repo' }
end

package 'staker-repo'

package "elrond-#{node['elrond']['network']}" do
  version node['elrond']['version']
end
