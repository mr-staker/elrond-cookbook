# frozen_string_literal: true

# runs through repository bootstrap - past this point, the actual
# management is handed over to the staker-repo package which deals with the
# repository configuration itself and the signing key rotation

package %w[gnupg2 apt-transport-https] do
  only_if { platform_family? 'debian' }
end

apt_repository 'staker' do
  key node['staker']['key']['fingerprint']
  # Keybase is rate limited and the silly thing drops packets intead of
  # returning an actual error
  keyserver 'keys.openpgp.org'

  uri 'https://deb.staker.ltd'
  distribution 'stable'
  components %w[main]

  only_if { platform_family? 'debian' }
  not_if { ::File.exist? '/etc/apt/sources.list.d/staker.list' }
end

yum_repository 'staker' do
  description 'Mr Staker rpm repository'
  baseurl 'https://rpm.staker.ltd/$basearch'
  # Keybase is rate limited and the silly thing drops packets intead of
  # returning an actual error
  gpgkey 'https://keys.openpgp.org/vks/v1/by-fingerprint/'\
         "#{node['staker']['key']['fingerprint']}"
  gpgcheck true
  repo_gpgcheck true

  only_if { platform_family? 'rhel' }
  not_if { ::File.exist? '/etc/yum.repos.d/staker.repo' }
end

package 'staker-repo'
