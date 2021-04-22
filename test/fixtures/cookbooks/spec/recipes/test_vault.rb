# setup a test Hashicorp vault to simulate a validator
# technically, the node itself is still an observer as for an actual validator
# you need to stake, but the idea is to simulate the key management capabilities
# of the elrond_keyvault resource

apt_package %w[gnupg2 apt-transport-https lsb-release] do
  only_if { platform_family? 'debian' }
end

apt_repository 'vault' do
  key 'https://apt.releases.hashicorp.com/gpg'
  uri 'https://apt.releases.hashicorp.com'
  distribution node['lsb']['codename']
  components %w[main]
  only_if { platform_family? 'debian' }
end

yum_repository 'vault' do
  description 'Vault Stable - $basearch'
  baseurl 'https://rpm.releases.hashicorp.com/RHEL/$releasever/$basearch/stable'
  gpgkey 'https://rpm.releases.hashicorp.com/gpg'
  gpgcheck true

  only_if { platform_family? 'rhel' }
end

package %w[vault psmisc]
