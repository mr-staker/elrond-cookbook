# frozen_string_literal: true

include_recipe 'elrond::semanage'
include_recipe 'elrond::monit'
include_recipe 'firewalld::default'

var_dir = node['elrond']['system']['var_dir']
version_change = "#{var_dir}/.version_change"

if platform_family? 'rhel'
  # RPM doesn't support dashes in version name due to use of epoch
  node.override['elrond']['version'] = node['elrond']['version'].tr('-', '_')
end

directory var_dir do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
end

# expire the cache to make sure new versions are being picked up on updates
execute 'yum clean expire-cache' do
  only_if { platform_family? 'rhel' }
end

package "elrond-#{node['elrond']['network']}" do
  version node['elrond']['version']
end

# workaround subscription bug i.e a resource running from witihin
# a custom resource fails to subscribe to a resource running from a recipe
ruby_block 'elrond-version' do
  block do
    File.write version_change, node['elrond']['version']
  end

  subscribes :run, "package[elrond-#{node['elrond']['network']}]", :immediately

  action :nothing
end

# configure journal log sizes
ini_file '/etc/systemd/journald.conf' do
  file_content(
    {
      'Journal' => {
        'Storage' => 'persistent',
        'SystemMaxUse' => '2048M',
        'SystemMaxFileSize' => '512M'
      }
    }
  )

  notifies :restart, 'service[systemd-journald]', :delayed

  action :edit
end

service 'systemd-journald' do
  action %i[enable start]
end

template '/etc/systemd/system/elrond-node@.service' do
  source 'etc/systemd/system/elrond-node@.service.erb'
  owner 'root'
  group 'root'
  mode '0644'

  variables(
    arwen: node['elrond']['system']['arwen'],
    var_dir: var_dir
  )

  notifies :run, 'execute[service-systemctl-daemon-reload]', :immediately
end

# where to seed the node keys
directory '/opt/etc/elrond/keyvault' do
  owner 'root'
  group 'root'
  mode '0700'
  recursive true
end

node['elrond']['nodes'].each do |elrond_node|
  unless elrond_node['id'] >= 0
    raise %(Error: node['elrond']['nodes'][N]['id'] values must be >= 0)
  end

  elrond_node "node-#{elrond_node['id']}" do
    id elrond_node['id'].to_i
    validator elrond_node['validator'] == true
    key_manager elrond_node['key_manager']&.to_sym || :elrond_keygen
    redundancy_level elrond_node['redundancy_level']&.to_i || 0

    if elrond_node['validator'] != true
      destination_shard elrond_node['destination_shard'] || 'disabled'
    end

    action elrond_node['action'].to_sym if elrond_node['action']
  end
end

execute 'service-systemctl-daemon-reload' do
  command 'systemctl daemon-reload'

  action :nothing
end

file version_change do
  action :delete
end

cookbook_file '/usr/bin/erctl' do
  source 'usr/bin/erctl'
  owner 'root'
  group 'root'
  mode '0755'
  # not really sensitive, but suppressing the output as it polutes the log
  sensitive true
end
