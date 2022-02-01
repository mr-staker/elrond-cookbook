# frozen_string_literal: true

resource_name :elrond_keyvault
provides :elrond_keyvault
unified_mode false

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

  vault_export "export-vault-key-#{id}" do
    file_path key_path

    address node['elrond']['keyvault']['address']
    token node['elrond']['keyvault']['token']

    secret_path "#{node['elrond']['keyvault']['path']}/node"
    secret_name id.to_s
    secret_key :validator_key

    only_if { validator == true }
  end

  # copy key from system store to config dir
  file "#{home_dir}/config/validatorKey.pem" do
    owner user
    group user
    mode '0400'
    content(lazy { ::File.read key_path })
    sensitive true
  end
end
