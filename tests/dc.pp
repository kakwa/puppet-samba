## kerberos is sensitive to time, 
## having an ntp might be a good idea
#class { '::ntp':
#  servers => [ 'pool.ntp.org' ],
#}

class { 'samba::params':
  sernetpkgs => false,
}

class { '::samba::dc':
  domain             => 'DC',
  realm              => 'dc.example.org',
  dnsbackend         => 'internal',
  domainlevel        => '2008 R2',
  sambaloglevel      => 1,
  logtosyslog        => true,
  ip                 => '192.168.199.80',
  sambaclassloglevel => {
    'smb'   => 2,
    'idmap' => 2,
  },
  dnsforwarder       => '192.168.199.42',
}

class { '::samba::dc::ppolicy':
  ppolicycomplexity    => 'on',
  ppolicyplaintext     => 'off',
  ppolicyhistorylength => 12,
  ppolicyminpwdlength  => 10,
  ppolicyminpwdage     => 1,
  ppolicymaxpwdage     => 90,
}

smb_user { 'administrator':
  ensure     => present,
  password   => 'c0mPL3xe_P455woRd',
  attributes => {
    uidNumber        => '15220',
    gidNumber        => '15220',
    msSFU30NisDomain => 'dc',
    scriptPath       => 'login1.cmd',
  },
  groups     => ['domain users', 'administrators'],
}

smb_group { 'mygroup':
  ensure     => present,
  scope      => 'Domain',
  type       => 'Security',
  attributes => {
    gidNumber        => '15222',
    msSFU30NisDomain => 'dc',
  },
  groups     => ['domain users', 'administrators'],
}

::samba::dc::script { 'login1.cmd':
    content => 'echo login script 1
ping -n 11 127.0.0.1 > nul
',
}

::samba::dc::script { 'login2.cmd':
    content => 'echo login script 2
ping -n 11 127.0.0.1 > nul
',
}
