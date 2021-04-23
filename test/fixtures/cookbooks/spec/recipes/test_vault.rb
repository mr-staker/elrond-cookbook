# setup a test Hashicorp vault to simulate a validator
# technically, the node itself is still an observer as for an actual validator
# you need to stake, but the idea is to simulate the key management capabilities
# of the elrond_keyvault resource

package %w[gnupg2 apt-transport-https lsb-release login] do
  only_if { platform_family? 'debian' }
end

package 'util-linux' do
  only_if { platform_family? 'rhel' }
end

apt_repository 'vault' do
  key 'https://apt.releases.hashicorp.com/gpg'
  uri 'https://apt.releases.hashicorp.com'
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

package 'vault'

# run test vault service
group 'test-vault' do
  system true
end

user 'test-vault' do
  gid 'test-vault'
  system true
  shell '/sbin/nologin'
end

systemd_unit 'test-vault.service' do
  content(
    {
      Unit: {
        Description: 'test-vault',
        After: 'network.target',
      },
      Service: {
        User: 'test-vault',
        Environment: [
          '"VAULT_DEV_ROOT_TOKEN_ID='\
            "#{node['elrond']['keyvault']['token']}\"",
          %("VAULT_ADDR=#{node['elrond']['keyvault']['address']}"),
        ],
        ExecStart: '/usr/bin/vault server -dev -dev-no-store-token',
      },
      Install: {
        WantedBy: 'multi-user.target',
      },
    }
  )
  action %i[create enable restart]
end

# allow easy interaction in kitchen - this file avoids messing up with
# bash's standard config
file '/home/kitchen/.bash_aliases' do
  owner 'kitchen'
  group 'kitchen'
  content <<~EOF
    export VAULT_TOKEN=#{node['elrond']['keyvault']['token']}
    export VAULT_ADDR=#{node['elrond']['keyvault']['address']}
  EOF
end

ruby_block 'seed-vault' do
  block do
    require 'vault'

    # give the test-vault service the opportunity to finis restarting
    sleep 2

    path = node['elrond']['keyvault']['path']
    key_path = "#{Chef::Config[:cookbook_path]}"\
      '/spec/files/default/validatorKey.pem'

    Vault.address = node['elrond']['keyvault']['address']
    Vault.token = node['elrond']['keyvault']['token']

    Vault.logical.write("#{path}/data/node/0", data: {
      validator_key: File.read(key_path),
    })
  end
end
