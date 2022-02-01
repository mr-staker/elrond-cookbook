resource_name :elrond_keygen
provides :elrond_keygen
unified_mode false

property :id, Integer
property :validator, [true, false], default: false

default_action :add

action :add do
  id = new_resource.id
  validator = new_resource.validator

  user = "elrond-node-#{id}"
  home_dir = "#{node['elrond']['system']['var_dir']}/node-#{id}"

  execute "keygen-#{id}" do
    user user
    cwd "#{home_dir}/config"
    command '/opt/elrond/bin/keygenerator'

    not_if { ::File.exist? "#{home_dir}/config/validatorKey.pem" }
    # validators must not use this resource
    only_if { validator == false }
  end

  # set/keep proper permissions
  file "#{home_dir}/config/validatorKey.pem" do
    owner user
    group user
    mode '0400'
    only_if { validator == false }
  end
end
