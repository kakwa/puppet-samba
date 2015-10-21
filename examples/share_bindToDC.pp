# example of a basic share, authenticating against a domain controller
node 'share.example.org' {

  class { 'samba::params':
    sernetpkgs => false,
  }

  class { '::ntp':
    servers => [ 'pool.ntp.org' ],
  }

  class { '::samba::classic':
    domain             => 'DC',
    realm              => 'dc.example.org',
    smbname            => 'SMB2',
    adminuser          => 'administrator',
    adminpassword      => 'c0mPL3xe_P455woRd',
    sambaloglevel      => 1,
    logtosyslog        => true,
    sambaclassloglevel => {
      'smb'     => 2,
      'idmap'   => 2,
      'winbind' => 2,
    },
    globaloptions      => {
      'winbind cache time' => 10,
    },
#    globaloptions       => {},
#    globalabsentoptions => [],
  }

  # recover uid and gid from Domain Controler (unix attributes)
  ::samba::idmap { 'Domain DC':
    domain      => 'DC',
    idrangemin  => 10000,
    idrangemax  => 19999,
    backend     => 'ad',
    schema_mode => 'rfc2307',
  }

  # a default map (*) is needed for idmap to work
  ::samba::idmap { 'Domain *':
    domain     => '*',
    idrangemin => 100000,
    idrangemax => 199999,
    backend    => 'tdb',
  }

  ::samba::share { 'Test Share':
    path    => '/srv/test/',
    mode    => '0775',
    owner   => 'root',
    group   => 'domain users',
    options => {
      'comment'   => 'My test share that I want',
      'browsable' => 'Yes',
      'read only' => 'No',
    },
  }

  ::samba::share { 'homes':
    path    => '/srv/home/home_%U',
    options => {
      'comment'        => 'Home Folder',
      'browsable'      => 'No',
      'read only'      => 'No',
      'directory mask' => '700',
      'create mask'    => '700',
      'root preexec'   => "smb-create-home.sh -d \
/srv/home/home_%U -u %U -m 700",
    },
  }
}
