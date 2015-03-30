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
  end

end
