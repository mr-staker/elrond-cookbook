var_dir = '/opt/var/elrond'
user = 'elrond-node-0'
home_dir = "#{var_dir}/node-0"

# common
directory var_dir do
  owner 'root'
  group 'root'
  mode '0755'
  recursive true
end

# for each service
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
# shelling out
ruby_block 'copy-config' do
  block do
    require 'fileutils'

    # use the config packaged from upstream as template
    FileUtils.cp_r '/opt/elrond/etc/elrond/node/config', home_dir
    FileUtils.chown_R user, user, home_dir
  end

  not_if { Dir.exist? "#{home_dir}/config" }
end

# validators must obtain their key from a secure source and have
# an offsite backup of their keychain
# this is not automatically generated as the loss of a validator key
# is catastrophic
bash 'keygen' do
  user user
  cwd "#{home_dir}/config"
  code '/opt/elrond/bin/keygenerator'

  not_if { ::File.exist? "#{home_dir}/config/validatorKey.pem" }
  only_if { node['elrond']['node']['validator'] == false }
end

service 'elrond-node@0' do
  action %i[enable start]
end
