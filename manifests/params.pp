class samba::params(
  $sernetRepo = true,
){
  unless is_bool($sernetRepo){
    fail('sernetRepo variable must be a boolean')
  }
  if $sernetRepo {
    case $::osfamily {
      'redhat': {
          $packageSambaDC      = 'sernet-samba-ad'
          $packageSambaClassic = 'sernet-samba'
          $serviveSambaDC      = 'sernet-samba-ad'
          $serviveSambaClassic = [ 'sernet-samba-smbd',
            'sernet-samba-winbindd' ]
          $sambaCmd            = '/usr/bin/samba-tool'
          $sambaClientCmd      = '/usr/bin/smbclient'
          $sambaOptsFile       = '/etc/default/sernet-samba'
          $sambaOptsTmpl       = "${module_name}/sernet-samba.erb"
          $smbConfFile         = '/etc/samba/smb.conf'
      }
      default: {
          fail('unsupported os')
      }
    }
  }else{
    case $::osfamily {
      'redhat': {
          fail('CentOS/RedHat don\'t support Samba 4 AD')
      }
      default: {
          fail('unsupported os')
      }
    }
  }

  $logclasslist =  [
    'all',     'tdb',     'printdrivers', 'lanman',   'smb',
    'rpc_srv', 'rpc_cli', 'passdb',       'sam',      'auth',
    'winbind', 'vfs',     'idmap',        'quota',    'acls',
    'locking', 'msdfs',   'dmapi',        'registry', 'rpc_parse',
    ]

}

# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
