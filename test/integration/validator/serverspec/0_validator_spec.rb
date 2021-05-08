require 'vault'

require_relative 'spec_helper'

describe 'elrond_keyvault' do
  describe package('vault') do
    it { should be_installed }
  end

  describe 'Vault KV "secret/node/0"' do
    path = node['elrond']['keyvault']['path']

    Vault.address = node['elrond']['keyvault']['address']
    Vault.token = node['elrond']['keyvault']['token']

    vault_secret = Vault.kv("#{path}/node").read('0')
    key = vault_secret.data[:validator_key]

    it { key.should match '0d7d1723f62337f684229ce4' }
  end
end
