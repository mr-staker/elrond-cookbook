var_dir = node['elrond']['system']['var_dir']

directory var_dir do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
end

# patch systemd unit template to use environment variables - systemd units are
# close enough to ini files that this would do
ini_file '/etc/systemd/system/elrond-node@.service' do
  file_content(
    {
      'Service' => {
        # allow parameters for template unit
        'EnvironmentFile' => "#{var_dir}/node-%i/config/service.env",
        'ExecStart' => '/opt/elrond/bin/node '\
          '-use-log-view '\
          '-log-level ${LOG_LEVEL} '\
          '-rest-api-interface localhost:${REST_API_PORT}',
      },
    }
  )
  action :edit
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
    id elrond_node['id']
    validator elrond_node['validator']
    key_manager elrond_node['key_manager']
  end
end
