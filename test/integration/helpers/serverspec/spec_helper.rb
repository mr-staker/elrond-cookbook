$LOAD_PATH.unshift(*Dir['/opt/cinc/embedded/lib/ruby/gems/**/lib'])

require 'json'
require 'fileutils'
require 'chef/node'
require 'serverspec'

set :backend, :exec

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
end

class ChefNodeWrapper
  def self.node
    @node ||= Chef::Node.from_hash JSON.parse(File.read('/tmp/node.json'))
  end
end

def node
  ChefNodeWrapper.node
end
