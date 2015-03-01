require 'spec_helper'
describe 'samba' do

  context 'with defaults for all parameters' do
    it { should contain_class('samba') }
  end
end
