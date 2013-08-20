require 'chefspec'

describe 'postfix-full::default' do
  let(:chef_runner) { ChefSpec::ChefRunner.new(
      :platform => 'ubuntu', :version => '12.04',
      :log_level => :error) }
  let(:chef_run) { chef_runner.converge 'postfix-full::default' }
  let(:main_cf) { '/etc/postfix/main.cf' }
  let(:master_cf) { '/etc/postfix/master.cf' }
  let(:resolv_conf) { '/var/spool/postfix/etc/resolv.conf' }

  context 'should install distribution packages' do
    it 'by default only postfix' do
      chef_run.should install_package 'postfix'
    end
    it 'with ldap table option postfix-ldap packages' do
      chef_runner.node.set['postfix']['main']['alias_maps'] = 'ldap:test'
      chef_run.should install_package 'postfix-ldap'
    end
    it 'with ldap table postfix-ldap packages' do
      chef_runner.node.set['postfix']['tables']['test']['_type'] = 'ldap'
      chef_run.should install_package 'postfix-ldap'
    end
  end

  it 'should configure main.cf' do
    chef_run.should create_file main_cf
    file = chef_run.file main_cf
    file.should be_owned_by('root', 0)
  end

  it 'should configure master.cf' do
    chef_run.should create_file master_cf
    file = chef_run.file master_cf
    file.should be_owned_by('root', 0)
  end

  it 'should setup postfix service' do
    chef_run.should start_service 'postfix'
    chef_run.should set_service_to_start_on_boot 'postfix'
  end

  it 'should create /etc/resolv.conf inside chroot' do
    chef_run.should create_file resolv_conf
    file = chef_run.file resolv_conf
    file.should be_owned_by('root', 'root')
    expect(file.mode).to eq('0644')
  end
end
