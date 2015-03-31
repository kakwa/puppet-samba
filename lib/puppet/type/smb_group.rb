Puppet::Type.newtype(:smb_group) do

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc 'Name of the group'
  end

  newparam(:attributes) do
    desc 'hash of attributes'
  end

  newparam(:groups) do
    desc 'list of groups'
    defaultto []
  end

  newparam(:scope) do
    desc 'scope of the group'
  end

  newparam(:type) do
    desc 'scope of the group'
  end

  autorequire(:service) do
    ['SambaDC',]
  end

  autorequire(:file) do
    ['SambaOptsAdditionnalTool',]
  end

end
