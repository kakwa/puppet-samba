# == Class: samba
#
# Full description of class samba here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'samba':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2015 Your name here, unless otherwise noted.
#

define samba::share(
  $path,
  $options = {},
  $absentoptions = [],
  $owner = 'root',
  $group = 'root',
  $mode  = '0777',
  $acl   = undef,
  $manage_directory = true,
) {

  if defined(Package['SambaClassic']){
    $require = Package['SambaClassic']
    if defined(Service['SambaWinbind']) {
      $notify  = Service['SambaSmb', 'SambaWinBind']
    }
    else {
      $notify  = Service['SambaSmb']
    }
  }elsif defined(Package['SambaDC']){
    $require = Exec['provisionAD']
    $notify  = Service['SambaDC']
  }else{
    fail('No mode matched, Missing class samba::classic or samba::dc?')
  }

  unless member(concat(keys($options), $absentoptions), 'path'){
    $rootpath = regsubst($path, '(^[^%]*/)[^%]*%.*', '\1')
    validate_absolute_path($rootpath)

    if $manage_directory {
      ::samba::dir {$rootpath:
        path  => $rootpath,
        owner => $owner,
        group => $group,
        mode  => $mode,
        acl   => $acl,
      }
    }

    smb_setting { "${name}/path":
      path    => $::samba::params::smbconffile,
      section => $name,
      setting => 'path',
      value   => $path,
      require => $require,
      notify  => $notify,
    }
  }

  $optionsindex = prefix(keys($options), "[${name}]")
  ::samba::option{ $optionsindex:
    options => $options,
    section => $name,
    require => $require,
    notify  => $notify,
  }

  $absoptlist = prefix($absentoptions, $name)
  smb_setting { $absoptlist :
    ensure  => absent,
    section => 'netlogon',
  }
}
