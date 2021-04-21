$LOAD_PATH.unshift(*Dir['/opt/cinc/embedded/lib/ruby/gems/**/lib'])

require 'json'
require 'chef/node'
require 'serverspec'

set :backend, :exec

class ChefNodeWrapper
  def self.node
    @node ||= Chef::Node.from_hash JSON.parse(File.read('/tmp/node.json'))
  end
end

def node
  ChefNodeWrapper.node
end
