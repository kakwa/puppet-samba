# default parameters

class samba::params(
  $sernetpkgs = false,
){
  unless is_bool($sernetpkgs){
    fail('sernetpkgs variable must be a boolean')
  }
  if $sernetpkgs {
    case $::osfamily {
      'redhat': {
          $packagesambadc      = 'sernet-samba-ad'
          $packagesambaclassic = 'sernet-samba'
          $packagesambaclient  = 'sernet-samba-client'
          $packagesambawinbind = 'sernet-samba-winbind'
          $servivesambadc      = 'sernet-samba-ad'
          $servivesmb          = 'sernet-samba-smbd'
          $servivewinbind      = 'sernet-samba-winbindd'
          $sambacmd            = '/usr/bin/samba-tool'
          $sambaclientcmd      = '/usr/bin/smbclient'
          $sambaoptsfile       = '/etc/default/sernet-samba'
          $sambaoptstmpl       = "${module_name}/sernet-samba.erb"
          $smbconffile         = '/etc/samba/smb.conf'
          $krbconffile         = '/etc/krb5.conf'
          $packagepyyaml       = 'PyYAML'
      }
      'Debian': {
          $packagesambadc      = 'sernet-samba-ad'
          $packagesambaclassic = 'sernet-samba'
          $packagesambaclient  = 'sernet-samba-client'
          $packagesambawinbind = 'sernet-samba-winbind'
          $servivesambadc      = 'sernet-samba-ad'
          $servivesmb          = 'sernet-samba-smbd'
          $servivewinbind      = 'sernet-samba-winbindd'
          $sambacmd            = '/usr/bin/samba-tool'
          $sambaclientcmd      = '/usr/bin/smbclient'
          $sambaoptsfile       = '/etc/default/sernet-samba'
          $sambaoptstmpl       = "${module_name}/sernet-samba.erb"
          $smbconffile         = '/etc/samba/smb.conf'
          $krbconffile         = '/etc/krb5.conf'
          $packagepyyaml       = 'python-yaml'
      }
      default: {
          fail('unsupported os')
      }
    }
  }else{
    case $::osfamily {
      'redhat': {
          $packagesambadc      = 'samba-dc'
          $packagesambaclassic = 'samba'
          $packagesambawinbind = 'samba-winbind'
          $packagesambaclient  = 'samba-client'
          # for now, this is not supported by Debian
          $servivesambadc      = undef
          $servivesmb          = 'smb'
          $servivewinbind      = 'winbind'
          $sambacmd            = '/usr/bin/samba-tool'
          $sambaclientcmd      = '/usr/bin/smbclient'
          $sambaoptsfile       = '/etc/sysconfig/samba'
          $sambaoptstmpl       = "${module_name}/redhat-samba.erb"
          $smbconffile         = '/etc/samba/smb.conf'
          $krbconffile         = '/etc/krb5.conf'
          $packagepyyaml       = 'PyYAML'
      }
      'Debian': {
          $packagesambadc      = 'samba'
          $packagesambaclassic = 'samba'
          $packagesambawinbind = 'winbind'
          $packagesambaclient  = 'smbclient'
          $servivesambadc      = 'samba-ad-dc'
        if $::operatingsystem == 'Ubuntu' {
          $servivesmb          = 'smbd'
        } elsif ($::operatingsystem == 'Debian') and ($::operatingsystemmajrelease >= '8') {
          $servivesmb          = 'smbd'
        } else {
          $servivesmb          = 'samba'
        }
          $servivewinbind      = 'winbind'
          $sambacmd            = '/usr/bin/samba-tool'
          $sambaclientcmd      = '/usr/bin/smbclient'
          $sambaoptsfile       = '/etc/default/samba4'
          $sambaoptstmpl       = "${module_name}/debian-samba.erb"
          $smbconffile         = '/etc/samba/smb.conf'
          $krbconffile         = '/etc/krb5.conf'
          $packagepyyaml       = 'python-yaml'
      }
      default: {
          fail('unsupported os')
      }
    }
  }

  $sambaaddtool     = '/usr/local/bin/additional-samba-tool'
  $nsswitchconffile = '/etc/nsswitch.conf'
  $sambacreatehome  = '/usr/local/bin/smb-create-home.sh'

  $logclasslist =  [
    'all',     'tdb',     'printdrivers', 'lanman',   'smb',
    'rpc_srv', 'rpc_cli', 'passdb',       'sam',      'auth',
    'winbind', 'vfs',     'idmap',        'quota',    'acls',
    'locking', 'msdfs',   'dmapi',        'registry', 'rpc_parse',
    ]
}

# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
