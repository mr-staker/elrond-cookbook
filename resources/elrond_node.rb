resource_name :elrond_node
provides :elrond_node

property :id, Integer
property :validator, [true, false], default: false
property :key_manager, String, default: 'elrond_keygen'

default_action :config

action :config do
  base_port = 8080

  id = new_resource.id
  validator = new_resource.validator
  key_manager = new_resource.key_manager

  user = "elrond-node-#{id}"
  home_dir = "#{node['elrond']['system']['var_dir']}/node-#{id}"

  group user do
    system true
  end

  user user do
    gid username
    home home_dir
    system true
    manage_home true
    shell '/bin/bash'
  end

  directory home_dir do
    owner user
    group user
    mode '0700'
  end

  # a script would do as well, but this is slighly faster as there's no
  # shelling out and more idiomatic as well
  ruby_block 'copy-config' do
    block do
      require 'fileutils'

      # use the config packaged from upstream as template
      FileUtils.cp_r '/opt/elrond/etc/elrond/node/config', home_dir
      FileUtils.chown_R user, user, home_dir
    end

    not_if { Dir.exist? "#{home_dir}/config" }
  end

  # pluggable key management - takes properties set by node['elrond']['nodes']
  # must produce a "#{home_dir}/config/validatorKey.pem" file
  # implemented resources by this cookbook
  # elrond_keygen - generates a key for observers
  # elrond_keyvault - reads a key from Hashicorp Valut and writes the result to
  # disk
  # you can define this in a custom cookbook and plug anything that
  # produces the same end result
  # n.b send is not a resource, but Object#send
  # https://apidock.com/ruby/Object/send
  # the resource is identified by the key_manager property
  send key_manager.to_sym, "key-#{id}" do
    id id
    validator validator
  end

  file "#{home_dir}/config/service.env" do
    owner user
    group user
    mode '0400'
    content <<~EOF
      REST_API_PORT=#{base_port + id}
      LOG_LEVEL=#{node['elrond']['node']['log_level']}
    EOF

    notifies :run, 'execute[elrond-systemctl-daemon-reload]', :immediately
    notifies :restart, "service[elrond-node@#{id}]", :delayed
  end

  execute 'elrond-systemctl-daemon-reload' do
    command 'systemctl daemon-reload'
    action :nothing
  end

  # this is a template systemd unit hence the @id bit
  service "elrond-node@#{id}" do
    action %i[enable start]
  end
end

# TODO
# action :remove do
# end
