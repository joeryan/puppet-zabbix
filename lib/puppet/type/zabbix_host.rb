# frozen_string_literal: true

Puppet::Type.newtype(:zabbix_host) do
  @doc = 'Manage zabbix hosts'

  ensurable do
    desc 'The basic property that the resource should be in.'
    defaultvalues
    defaultto :present
  end

  def initialize(*args)
    super

    # Migrate group to groups
    return if self[:group].nil?

    self[:groups] = self[:group]
    delete(:group)
  end

  def munge_boolean(value)
    case value
    when true, 'true', :true
      true
    when false, 'false', :false
      false
    else
      raise(Puppet::Error, 'munge_boolean only takes booleans')
    end
  end

  def munge_encryption(value)
    case value
    when 1, 'unencrypted', :unencrypted
      1
    when 2, 'psk', :psk
      2
    when 4, 'cert', :cert
      4
    else
      raise(Puppet::Error, 'munge_encryption only takes unencrypted, psk or cert')
    end
  end

  newparam(:hostname, namevar: true) do
    desc 'FQDN of the machine.'
  end

  newproperty(:id) do
    desc 'Internally used hostid'

    validate do |_value|
      raise(Puppet::Error, 'id is read-only and is only available via puppet resource.')
    end
  end

  newproperty(:interfaceid) do
    desc 'Internally used identifier for the host interface'

    validate do |_value|
      raise(Puppet::Error, 'interfaceid is read-only and is only available via puppet resource.')
    end
  end

  newproperty(:ipaddress) do
    desc 'The IP address of the machine running zabbix agent.'
  end

  newproperty(:interfacetype, int: 1) do
    desc 'Interface type. 1 for zabbix agent.'
  end

  newproperty(:interfacedetails) do
    desc 'Additional interface details.'

    def insync?(is)
      is.to_s == should.to_s
    end
  end

  newproperty(:use_ip, boolean: true) do
    desc 'Using ipadress instead of dns to connect.'

    newvalues(true, false)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newproperty(:port) do
    desc 'The port that the zabbix agent is listening on.'
    def insync?(is)
      is.to_i == should.to_i
    end
  end

  newproperty(:group) do
    desc 'Deprecated! Name of the hostgroup.'

    validate do |_value|
      Puppet.warning('Passing group to zabbix_host is deprecated and will be removed. Use groups instead.')
    end
  end

  newproperty(:groups, array_matching: :all) do
    desc 'An array of groups the host belongs to.'
    def insync?(is)
      is.sort == should.sort
    end
  end

  newparam(:group_create, boolean: true) do
    desc 'Create hostgroup if missing.'

    newvalues(true, false)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  newproperty(:templates, array_matching: :all) do
    desc 'List of templates which should be loaded for this host.'
    def insync?(is)
      is.sort == should.sort
    end
  end

  newproperty(:macros, array_matching: :all) do
    desc 'Array of hashes (macros) which should be loaded for this host.'
    def insync?(is)
      is.sort_by(&:first) == should.sort_by(&:first)
    end
  end

  newproperty(:proxy) do
    desc 'Whether it is monitored by an proxy or not.'
  end

  newproperty(:tls_connect) do
    desc 'How the server connect to the client (unencrypted, psk or cert)'
    def insync?(is)
      is.to_i == should.to_i
    end

    munge do |value|
      @resource.munge_encryption(value)
    end
  end

  newproperty(:tls_accept) do
    desc 'How the client connect to the server (unencrypted, psk or cert)'
    def insync?(is)
      is.to_i == should.to_i
    end

    munge do |value|
      @resource.munge_encryption(value)
    end
  end

  newproperty(:tls_issuer) do
    desc 'Certificate issuer.'
  end

  newproperty(:tls_subject) do
    desc 'Certificate subject.'
  end

  autorequire(:file) { '/etc/zabbix/api.conf' }

  validate do
    raise(_('The properties group and groups are mutually exclusive.')) if self[:group] && self[:groups]
  end
end
