# default parameters

class samba::params(
  Boolean $sernetpkgs = false,
){
  if $sernetpkgs {
    fail('sernetpkgs is not supported anymore as these packages are EOL')
  }else{
    case $facts['os']['family'] {
      'redhat': {
          $cleanup                = undef
          $packagesambadc         = 'samba-dc'
          $packagesambaclassic    = 'samba'
          $packagesambawinbind    = 'samba-winbind'
          $packagesambansswinbind = 'samba-winbind-clients'
          $packagesambapamwinbind = 'samba-winbind-clients'
          $packagesambaclient     = 'samba-client'
          # for now, this is not supported by Debian
          $servivesambadc         = undef
          $servivesmb             = 'smb'
          $servivewinbind         = 'winbind'
          $sambacmd               = '/usr/bin/samba-tool'
          $sambaclientcmd         = '/usr/bin/smbclient'
          $sambaoptsfile          = '/etc/sysconfig/samba'
          $sambaoptstmpl          = "${module_name}/redhat-samba.erb"
          $smbconffile            = '/etc/samba/smb.conf'
          $krbconffile            = '/etc/krb5.conf'
          $packagepyyaml          = 'PyYAML'
      }
      'Debian': {
          $cleanup                = 'pkill -9 smbd; pkill -9 nmbd; pkill -9 samba; rm -rf /var/run/samba; /bin/true'
          $packagesambadc         = 'samba'
          $packagesambaclassic    = 'samba'
          $packagesambawinbind    = 'winbind'
          $packagesambansswinbind = 'libnss-winbind'
          $packagesambapamwinbind = 'libpam-winbind'
          $packagesambaclient     = 'smbclient'
          $servivesambadc         = 'samba-ad-dc'
          if $facts['os']['name'] == 'Ubuntu' {
            $servivesmb           = 'smbd'
          } elsif ($facts['os']['name'] == 'Debian') and ($facts['os']['release']['major'] >= '8') {
            $servivesmb           = 'smbd'
          } else {
            $servivesmb           = 'samba'
          }
          $servivewinbind         = 'winbind'
          $sambacmd               = '/usr/bin/samba-tool'
          $sambaclientcmd         = '/usr/bin/smbclient'
          $sambaoptsfile          = '/etc/default/samba4'
          $sambaoptstmpl          = "${module_name}/debian-samba.erb"
          $smbconffile            = '/etc/samba/smb.conf'
          $krbconffile            = '/etc/krb5.conf'
          $packagepyyaml          = 'python-yaml'
      }
      'Archlinux': {
          $cleanup                = undef
          $packagesambadc         = 'samba'
          $packagesambaclassic    = 'samba'
          $packagesambawinbind    = 'libwbclient'
          $packagesambansswinbind = 'libnss-winbind'
          $packagesambapamwinbind = 'libpam-winbind'
          $packagesambaclient     = 'smbclient'
          $servivesambadc         = 'samba'
          $servivesmb             = 'smbd'
          $servivewinbind         = 'winbindd'
          $sambacmd               = '/usr/bin/samba-tool'
          $sambaclientcmd         = '/usr/bin/smbclient'
          $sambaoptsfile          = '/etc/default/samba4'
          $sambaoptstmpl          = "${module_name}/debian-samba.erb"
          $smbconffile            = '/etc/samba/smb.conf'
          $krbconffile            = '/etc/krb5.conf'
          $packagepyyaml          = 'python2-yaml'
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
