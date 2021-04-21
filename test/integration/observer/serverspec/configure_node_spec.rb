require_relative 'spec_helper'

describe 'elrond::configure_node' do
  describe file('/opt/var/elrond/node-0') do
    it { should be_directory }
  end

  describe user('elrond-node-0') do
    it { should exist }
  end

  describe group('elrond-node-0') do
    it { should exist }
  end

  describe file('/opt/var/elrond/node-0/config/validatorKey.pem') do
    it { should exist }
  end

  describe service('elrond-node@0') do
    it { should be_enabled }
    it { should be_running.under('systemd') }
  end
end
