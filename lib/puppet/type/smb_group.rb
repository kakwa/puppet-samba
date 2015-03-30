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

end
