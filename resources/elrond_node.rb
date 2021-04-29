resource_name :elrond_node
provides :elrond_node

property :id, Integer
property :validator, [true, false], default: false
property :key_manager, Symbol, default: :elrond_keygen
property :redundancy_level, Integer, default: 0

default_action :config

action :config do
  id = new_resource.id

  # conventions
  rest_api_base_port = 8080
  p2p_base_port = 37373

  user = "elrond-node-#{id}"
  var_dir = node['elrond']['system']['var_dir']
  home_dir = "#{node['elrond']['system']['var_dir']}/node-#{id}"
  node_display_name = "#{node['elrond']['staking']['agency']}-"\
    "#{node['elrond']['network'].capitalize}-#{id}"

  # resources
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

  # wipe config upon version changes - this shall be cloned from distribution
  directory "#{home_dir}/config" do
    recursive true
    only_if { ::File.exist? "#{var_dir}/.version_change" }

    notifies :restart, "service[elrond-node@#{id}]", :delayed

    action :delete
  end

  # a script would do as well, but this is slighly faster as there's no
  # shelling out and more idiomatic as well
  ruby_block 'copy-config' do
    block do
      require 'fileutils'

      # use the config packaged from upstream as template config
      FileUtils.cp_r '/opt/elrond/etc/elrond/node/config', home_dir
      FileUtils.chown_R user, user, home_dir
    end

    not_if { Dir.exist? "#{home_dir}/config" }

    notifies :restart, "service[elrond-node@#{id}]", :delayed
  end

  toml_file "#{home_dir}/config/p2p.toml" do
    file_content(
      {
        'Node' => {
          'Port' => "#{p2p_base_port + id}",
        },
      }
    )

    notifies :restart, "service[elrond-node@#{id}]", :delayed

    action :edit
  end

  toml_file "#{home_dir}/config/prefs.toml" do
    file_content(
      {
        'Preferences' => {
          'NodeDisplayName' => node_display_name,
          'Identity' => node['elrond']['keybase']['identity'],
          'RedundancyLevel' => new_resource.redundancy_level,
        },
      }
    )

    notifies :restart, "service[elrond-node@#{id}]", :delayed

    action :edit
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
  send new_resource.key_manager, "key-#{id}" do
    id id
    validator new_resource.validator

    notifies :restart, "service[elrond-node@#{id}]", :delayed
  end

  file "#{home_dir}/config/service.env" do
    owner user
    group user
    mode '0400'
    content <<~EOF
      REST_API_PORT=#{rest_api_base_port + id}
      LOG_LEVEL=#{node['elrond']['node']['log_level']}
    EOF

    notifies :restart, "service[elrond-node@#{id}]", :delayed
    notifies :run, 'execute[elrond-systemctl-daemon-reload]', :immediately
  end

  # this is a duplication of the resource found in elrond::configure_node
  # to workaround subscription bug
  execute 'elrond-systemctl-daemon-reload' do
    command 'systemctl daemon-reload'

    action :nothing
  end

  # selinux on bare metal servers with the default policy may fail if /opt
  # is mounted on separate volume hence setting this context
  semanage_fcontext "#{home_dir}/config/service.env" do
    type 'systemd_runtime_unit_file_t'

    only_if { platform_family? 'rhel' }
  end

  # this is a template systemd unit hence the @id bit
  service "elrond-node@#{id}" do
    action %i[enable start]
  end
end

# TODO
# action :remove do
# end
