require 'puppet/parameter/boolean'

Puppet::Type.newtype(:smb_user) do

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'Name of the user'
  end

  newparam(:use_username_as_cn, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Force use of username as user\'s CN'
    defaultto false
  end

  newparam(:given_name) do
    desc 'User\'s given name'
    defaultto ''
  end

  newparam(:attributes) do
    desc 'hash of attributes'
    defaultto {}
  end

  newparam(:password) do
    desc 'password of the user'
  end

  newparam(:force_password, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'force the password value (if false, only set password at creation time)'
    defaultto true
  end

  newparam(:groups) do
    desc 'list of groups'
    defaultto []
  end

  autorequire(:service) do
    ['SambaDC',]
  end

  autorequire(:file) do
    ['SambaOptsAdditionnalTool',]
  end

end
