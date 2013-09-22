require 'spec_helper'

describe 'postfix-full::default' do
  let(:chef_runner) { ChefSpec::ChefRunner.new(
      :platform => 'ubuntu', :version => '12.04',
      :log_level => :error) }
  let(:main_cf) { '/etc/postfix/main.cf' }
  let(:master_cf) { '/etc/postfix/master.cf' }
  subject { chef_runner.converge 'postfix-full::default' }

  context 'should install distribution packages' do
    it 'per default only postfix' do
      should install_package 'postfix'
    end

    context 'with ldap table option' do
      before { chef_runner.node.set['postfix']['main']['alias_maps'] = 'ldap:test' }
      it { should install_package 'postfix-ldap' }
    end

    context 'with ldap table' do
      before { chef_runner.node.set['postfix']['tables']['test']['_type'] = 'ldap' }
      it { should install_package 'postfix-ldap' }
    end
  end

  context '\'s main.cf administration' do
    it { should create_file main_cf }
    it { expect(subject.file main_cf).to be_owned_by('root', 0) }
  end

  context '\'s master.cf administration' do
    it { should create_file master_cf }
    it { expect(subject.file master_cf).to be_owned_by('root', 0) }
  end

  it { should start_service 'postfix' }
  it { should set_service_to_start_on_boot 'postfix' }
end
