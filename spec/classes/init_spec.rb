require 'spec_helper'
describe 'snmptt' do
  context 'with default values for all parameters' do
    it { is_expected.to contain_class('snmptt') }
  end
end
