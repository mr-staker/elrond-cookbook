require_relative 'spec_helper'

# this is technically not a helper, but it is a convenient way of sharing tests
# across multiple suites

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
    it { should be_owned_by 'elrond-node-0' }
    it { should be_grouped_into 'elrond-node-0' }
    it { should be_mode '400' }
  end

  describe service('elrond-node@0') do
    it { should be_enabled }
    it { should be_running.under('systemd') }
  end
end
