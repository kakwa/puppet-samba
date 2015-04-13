# default parameters

class samba::params(
  $sernetRepo = false,
){
  unless is_bool($sernetRepo){
    fail('sernetRepo variable must be a boolean')
  }
  if $sernetRepo {
    case $::osfamily {
      'redhat': {
          $packageSambaDC      = 'sernet-samba-ad'
          $packageSambaClassic = 'sernet-samba'
          $packageSambaWinBind = 'sernet-samba-winbind'
          $serviveSambaDC      = 'sernet-samba-ad'
          $serviveSmb          = 'sernet-samba-smbd'
          $serviveWinBind      = 'sernet-samba-winbindd'
          $sambaCmd            = '/usr/bin/samba-tool'
          $sambaClientCmd      = '/usr/bin/smbclient'
          $sambaOptsFile       = '/etc/default/sernet-samba'
          $sambaOptsTmpl       = "${module_name}/sernet-samba.erb"
          $smbConfFile         = '/etc/samba/smb.conf'
          $krbConfFile         = '/etc/krb5.conf'
          $packagePyYaml       = 'PyYAML'
      }
      'Debian': {
          $packageSambaDC      = 'sernet-samba-ad'
          $packageSambaClassic = 'sernet-samba'
          $packageSambaWinBind = 'sernet-samba-winbind'
          $serviveSambaDC      = 'sernet-samba-ad'
          $serviveSmb          = 'sernet-samba-smbd'
          $serviveWinBind      = 'sernet-samba-winbindd'
          $sambaCmd            = '/usr/bin/samba-tool'
          $sambaClientCmd      = '/usr/bin/smbclient'
          $sambaOptsFile       = '/etc/default/sernet-samba'
          $sambaOptsTmpl       = "${module_name}/sernet-samba.erb"
          $smbConfFile         = '/etc/samba/smb.conf'
          $krbConfFile         = '/etc/krb5.conf'
          $packagePyYaml       = 'python-yaml'
      }
      default: {
          fail('unsupported os')
      }
    }
  }else{
    case $::osfamily {
      'redhat': {
          $packageSambaDC      = 'samba-dc'
          $packageSambaClassic = 'samba'
          $packageSambaWinBind = 'samba-winbind'
          # for now, this is not supported by Debian
          $serviveSambaDC      = undef
          $serviveSmb          = 'smb'
          $serviveWinBind      = 'winbind'
          $sambaCmd            = '/usr/bin/samba-tool'
          $sambaClientCmd      = '/usr/bin/smbclient'
          $sambaOptsFile       = '/etc/sysconfig/samba'
          $sambaOptsTmpl       = "${module_name}/redhat-samba.erb"
          $smbConfFile         = '/etc/samba/smb.conf'
          $krbConfFile         = '/etc/krb5.conf'
          $packagePyYaml       = 'PyYAML'
      }
      'Debian': {
          $packageSambaDC      = 'samba'
          $packageSambaClassic = 'samba'
          $packageSambaWinBind = 'winbind'
          $serviveSambaDC      = 'samba-ad-dc'
          $serviveSmb          = 'samba'
          $serviveWinBind      = 'winbind'
          $sambaCmd            = '/usr/bin/samba-tool'
          $sambaClientCmd      = '/usr/bin/smbclient'
          $sambaOptsFile       = '/etc/default/samba4'
          $sambaOptsTmpl       = "${module_name}/debian-samba.erb"
          $smbConfFile         = '/etc/samba/smb.conf'
          $krbConfFile         = '/etc/krb5.conf'
          $packagePyYaml       = 'python-yaml'
      }
      default: {
          fail('unsupported os')
      }
    }
  }

  $sambaAddTool     = '/usr/local/bin/additional-samba-tool'
  $nsswitchConfFile = '/etc/nsswitch.conf'
  $sambaCreateHome  = '/usr/local/bin/smb-create-home.sh'

  $logclasslist =  [
    'all',     'tdb',     'printdrivers', 'lanman',   'smb',
    'rpc_srv', 'rpc_cli', 'passdb',       'sam',      'auth',
    'winbind', 'vfs',     'idmap',        'quota',    'acls',
    'locking', 'msdfs',   'dmapi',        'registry', 'rpc_parse',
    ]
}

# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
