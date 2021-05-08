resource_name :elrond_keyvault
provides :elrond_keyvault

property :id, Integer
property :validator, [true, false], default: true

default_action :add

action :add do
  id = new_resource.id
  validator = new_resource.validator

  user = "elrond-node-#{id}"
  home_dir = "#{node['elrond']['system']['var_dir']}/node-#{id}"

  # read key from Vault and place into system store
  # n.b this only supports Vault KV V2 paths
  key_path = "/opt/etc/elrond/keyvault/#{id}.pem"

  ruby_block "export-vault-key-#{id}" do
    block do
      require 'vault'
      require 'fileutils'

      path = node['elrond']['keyvault']['path']

      ::Vault.address = node['elrond']['keyvault']['address']
      ::Vault.token = node['elrond']['keyvault']['token']

      if node['elrond']['keyvault']['ssl_ciphers']
        ::Vault.ssl_ciphers = node['elrond']['keyvault']['ssl_ciphers']
      end

      vault_secret = ::Vault.logical.read "#{path}/data/node/#{id}"

      ::File.write key_path, vault_secret.data[:data][:validator_key]
      ::FileUtils.chmod 0400, key_path
    end

    only_if { validator == true }
    not_if { ::File.exist? key_path }
  end

  # copy key from system store to config dir
  file "#{home_dir}/config/validatorKey.pem" do
    owner user
    group user
    mode '0400'
    content lazy { ::File.read key_path }
    sensitive true
  end
end
