package { 'smbclient':
  ensure => 'present',
}

class { '::samba::classic':
  domain         => 'vagrant',
  realm          => 'vagrant.local',
  nsswitch       => false,
  manage_winbind => false,
  smbname        => 'SMB',
  security       => 'user',
  join_domain    => false,
}

::samba::share { 'share':
  path             => '/srv/share',
  manage_directory => true,
  owner            => 'vagrant',
  group            => 'vagrant',
  mode             => '0775',
  acl              => [],
  options          => {
    'browsable'   => 'Yes',
    'writeable'   => 'Yes',
    'force user'  => 'vagrant',
    'force group' => 'vagrant',
  }
}

# Add a local SMB test user
exec { 'add-smb-user':
  # See https://stackoverflow.com/questions/12009/piping-password-to-smbpasswd/53428249
  command => 'yes vagrant|head -n 2|smbpasswd -a -s vagrant',
  unless  => "pdbedit -L|grep \"^vagrant:\"",
  path    => ['/bin', '/usr/bin'],
}
