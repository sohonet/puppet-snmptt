require 'spec_helper'
describe 'snmptt' do
  context 'with default values for all parameters' do
    it { should contain_class('snmptt') }
  end
end
