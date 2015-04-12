require File.join(File.dirname(__FILE__), '..', 'smb_acl')

Puppet::Type.type(:smb_acl).provide(:genericacl, :parent => Puppet::Provider::Smb_Acl) do

end
