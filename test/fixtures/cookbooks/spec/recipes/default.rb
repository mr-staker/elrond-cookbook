# allow test-kitchen busser to continue working as if this is Chef
# Cinc Workstation may be a bit inconsitent depending on which client is used
# on the box and kitchen driver
link '/opt/chef' do
  to '/opt/cinc'
  not_if { ::File.exist? '/opt/chef' }
end

# allow Serverspec to load the node object via spec_helper
ruby_block 'dump_node' do
  block do
    File.write '/tmp/node.json', node.to_json
  end
end

include_recipe 'spec::test_vault'
