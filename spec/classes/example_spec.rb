require 'spec_helper'

os = ENV['BEAKER_set'] ||= 'centos6'

case os
when /default/
  osversion = '6'
when /centos6/
  osversion = '6'
when /centos7/
  osversion = '7'
else
  raise "Operating system: #{os} is not supported"
end

describe 'aws_nat_failover' do

  include_context "hieradata"
  include_context "facter"

  context 'supported operating systems' do
    describe "aws_nat_failover class without any parameters on CentOS #{osversion}" do
      let(:params) {{ }}
      let(:facts) do
        default_facts.merge({
        :operatingsystemmajrelease => osversion,
        })
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('aws_nat_failover') }
      it { is_expected.to contain_class('aws_nat_failover::params') }

      it { is_expected.to contain_class('aws_nat_failover::install').that_comes_before('aws_nat_failover::config') }
      it { is_expected.to contain_class('aws_nat_failover::config') }
      it { is_expected.to contain_class('aws_nat_failover::service').that_subscribes_to('aws_nat_failover::config') }


      ## Amend as appropriate
      # it { is_expected.to contain_service('aws_nat_failover') }
      # it { is_expected.to contain_package('aws_nat_failover').with_ensure('present') }

    end
  end

end
