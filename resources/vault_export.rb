# frozen_string_literal: true

resource_name :vault_export
provides :vault_export
unified_mode false

property :file_path, String, name_property: true
property :address, String, required: true
property :token, String, required: true
property :secret_path, String, required: true
property :secret_name, String, required: true
property :secret_key, Symbol
property :ssl_ciphers, String

default_action :export

action :export do
  file_path = new_resource.file_path
  address = new_resource.address
  token = new_resource.token
  secret_path = new_resource.secret_path
  secret_name = new_resource.secret_name
  secret_key = new_resource.secret_key
  ssl_ciphers = new_resource.ssl_ciphers

  ruby_block new_resource.name do
    block do
      require 'vault'
      require 'fileutils'

      ::Vault.address = address
      ::Vault.token = token
      ::Vault.ssl_ciphers = ssl_ciphers if ssl_ciphers
      secret = ::Vault.kv(secret_path).read(secret_name)

      if secret_key
        ::File.write file_path, secret.data[secret_key]
      else
        ::File.write file_path, YAML.dump(secret.data)
      end

      ::FileUtils.chmod 0o400, file_path
    end

    not_if { ::File.exist? file_path }
  end
end
