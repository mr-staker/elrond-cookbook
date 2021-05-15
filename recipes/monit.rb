# setup epel
package 'epel-release' do
  only_if { platform? 'redhat', 'centos', 'amazon' }
end

package 'oracle-epel-release-el8' do
  only_if { platform? 'oracle' }
end

package 'monit'

file '/etc/init.d/monit' do
  action :delete
end

%w[
  /etc/monit /etc/monit/conf.d /var/lib/monit
].each do |dir|
  directory dir do
    owner 'root'
    group 'root'
    mode '0755'
  end
end

directory '/var/lib/monit/events' do
  owner 'root'
  group 'root'
  mode '0700'
end

cookbook_file '/etc/monit/monit.conf' do
  source 'etc/monit/monit.conf'
  owner 'root'
  group 'root'
  mode '0600'

  notifies :restart, 'systemd_unit[monit.service]', :delayed
end

systemd_unit 'monit.service' do
  content(
    {
      Unit: {
        Description: 'daemon monitoring daemon',
        After: 'network.target',
      },
      Service: {
        Type: 'simple',
        ExecStart: '/usr/bin/monit -I -c /etc/monit/monit.conf',
        ExecStop: '/usr/bin/monit quit',
        ExecReload: '/usr/bin/monit reload',
        Restart: 'on-failure',
        RestartSec: '60s',
      },
      Install: {
        WantedBy: 'multi-user.target',
      },
    }
  )
  action %i[create enable restart]
end

cookbook_file '/usr/bin/monit-cli' do
  source 'usr/bin/monit-cli'
  owner 'root'
  group 'root'
  mode '0755'
end
