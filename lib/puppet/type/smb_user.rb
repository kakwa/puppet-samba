Puppet::Type.newtype(:smb_user) do

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'Name of the user'
  end

  newparam(:attributes) do
    desc 'hash of attributes'
    defaultto {}
  end

  newparam(:password) do
    desc 'password of the user'
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
