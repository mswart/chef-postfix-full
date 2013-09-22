require 'spec_helper'

shared_examples 'chroot_file' do |chroot_file|
  let(:path_in_chroot) { "#{queue_directory}/#{chroot_file}" }

  it { should create_file path_in_chroot }
  it { expect(subject.file path_in_chroot).to be_owned_by('root', 'root') }
  it { expect(subject.file(path_in_chroot).mode).to eq('0644') }
end

describe 'postfix-full::default' do
  let(:chef_runner) { ChefSpec::ChefRunner.new(
      :platform => 'ubuntu', :version => '12.04',
      :log_level => :error) }
  let(:main_cf) { '/etc/postfix/main.cf' }
  let(:master_cf) { '/etc/postfix/master.cf' }
  let(:queue_directory) { '/var/spool/postfix' }

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

  context 'chroot' do
    [
      'etc/resolv.conf',
      'etc/localtime',
      'etc/services',
      'etc/resolv.conf',
      'etc/hosts',
      'etc/nsswitch.conf',
      'etc/nss_mdns.config',
    ].each do |chroot_file|
      context "file #{chroot_file}" do
        include_examples 'chroot_file', chroot_file
      end
    end

    context 'additional file' do
      let(:chroot_file) { 'etc/mailname' }
      let(:path_in_chroot) { "#{queue_directory}/#{chroot_file}" }
    end

    context 'and an handling mode as symbol' do
      before { chef_runner.node.set['postfix']['chroot_files']['etc/hosts'] = :cp }

      include_examples 'chroot_file', 'etc/hosts'
    end

    context 'and an unknown handling mode' do
      before { chef_runner.node.set['postfix']['chroot_files']['etc/hosts'] = 'unknown' }

      it { should log(/Unsupported chroot file action: unknown/) }
    end
  end
end
