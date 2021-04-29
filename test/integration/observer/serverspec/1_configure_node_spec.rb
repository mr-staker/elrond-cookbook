require_relative 'spec_helper'

describe 'elrond::configure_node: 1' do
  describe service('elrond-node@1') do
    it { should be_enabled }
    it { should be_running.under('systemd') }
  end

  describe port(37374) do
    it { should be_listening.on('0.0.0.0').with('tcp') }
  end

  describe file('/etc/firewalld/services/node-1.xml') do
    it { should be_file }
    its(:content) { should match 'port="37374"' }
  end
end
