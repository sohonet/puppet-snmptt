require 'spec_helper'

describe 'snmptt' do
  test_on = {
    supported_os: [
      {
        'operatingsystem' => 'CentOS',
        'operatingsystemrelease' => %w[6],
      },
      {
        'operatingsystem' => 'Debian',
        'operatingsystemrelease' => %w[8 9],
      },
      {
        'operatingsystem' => 'Ubuntu',
        'operatingsystemrelease' => %w[16.04 18.04],
      },
    ],
  }

  on_supported_os(test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

      context 'with default values for all parameters' do
        it { is_expected.to contain_class('snmptt') }
        it { is_expected.to contain_file('/etc/snmp/snmptt.ini').with_content(%r{net_snmp_perl_enable = 0}) }

        it { is_expected.not_to contain_file('/etc/snmp/snmptt.sql') }
      end

      context 'with net_snmp_perl_enable' do
        let(:params) { { 'net_snmp_perl_enable' => true } }

        it { is_expected.to contain_file('/etc/snmp/snmptt.ini').with_content(%r{net_snmp_perl_enable = 1}) }
      end

      context 'with mysql' do
        let(:params) do
          {
            'enable_mysql'   => true,
            'mysql_password' => 'secret',
          }
        end

        it { is_expected.to contain_file('/etc/snmp/snmptt.sql') }
      end
    end
  end
end
