require_relative 'spec_helper'

describe 'elrond::install' do
  # cookstyle:disable Chef/Style/UsePlatformHelpers
  if node['platform_family'] == 'debian'
    %w[gnupg2 apt-transport-https].each do |pkg|
      describe package(pkg) do
        it { should be_installed }
      end
    end

    # there's no apt repo resource
    describe file('/etc/apt/sources.list.d/staker.list') do
      it { should exist }
      its(:content) { should match 'deb\.staker\.ltd' }
    end
  end

  if node['platform_family'] == 'rhel'
    describe yumrepo('staker') do
      it { should exist }
      it { should be_enabled }
    end
  end
  # cookstyle:enable Chef/Style/UsePlatformHelpers

  describe package('staker-repo') do
    it { should be_installed }
  end

  network = node['elrond']['network']
  version = node['elrond']['version']

  describe package("elrond-#{network}") do
    it { should be_installed }
    it { should be_installed.with_version(version) }
  end
end
