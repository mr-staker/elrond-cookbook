require_relative 'spec_helper'

describe 'elrond::configure_node: 1' do
  describe service('elrond-node@1') do
    it { should be_enabled }
    it { should be_running.under('systemd') }
  end
end
