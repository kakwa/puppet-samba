# The baseline for module testing used by Puppet Labs is that each manifest
# should have a corresponding test manifest that declares that class or defined
# type.
#
# Tests are then run by using puppet apply --noop (to check for compilation
# errors and view a log of events) or by fully applying the test in a virtual
# environment (to compare the resulting system state to the desired state).
#
# Learn more about module testing here:
# http://docs.puppetlabs.com/guides/tests_smoke.html
#

class { 'samba::params':
  sernetpkgs   => false,
}

class { '::samba::classic':
  domain              => 'DC',
  realm               => 'dc.kakwa.fr',
  smbname             => 'SMB',
  join_domain         => false,
  sambaloglevel       => 3,
  logtosyslog         => true,
  sambaclassloglevel  => {
    'smb'     => 2,
    'idmap'   => 10,
    'winbind' => 10,
  },
  globaloptions       => {
    'server string'      => 'Domain Controler',
    'winbind cache time' => 10,
  },
  globalabsentoptions => [
    'idmap_ldb:use rfc2307',
  ],
}

::samba::idmap { 'Domain DC':
  domain      => 'DC',
  idrangemin  => 10000,
  idrangemax  => 19999,
  backend     => 'ad',
  schema_mode => 'rfc2307',
}

::samba::idmap { 'Domain *':
  domain     => '*',
  idrangemin => 100000,
  idrangemax => 199999,
  backend    => 'tdb',
}

::samba::share { 'Test Share':
  # Mandatory parameters
  path    => '/srv/test/',
  # Optionnal parameters
  options => {             # * Custom options in section [global]
    'comment'   => 'My test share that I want',
    'browsable' => 'Yes',
    'read only' => 'No',
  },
  mode    => '0770',
  acl     =>
    [
      'group::rwx',
      'd:group:nogroup:rwx',
      'd:group:puppet:r-x',
      'mask::rwx' ,
      'other::---',
      'user::rwx',
    ],
}
