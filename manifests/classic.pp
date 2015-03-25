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
# Pierre-Francois Carpentier <carpentier.pf@gmail.com>
#
# === Copyright
#
# Copyright 2015 Pierre-Francois Carpentier, unless otherwise noted.
#

class samba::classic(
  $smbname              = undef,
  $domain               = undef,
  $realm                = undef,
  $adminpassword        = undef,
  $idrangemin           = undef,
  $idrangemax           = undef,
  $sambaloglevel        = 1,
  $sambaclassloglevel   = undef,
  $logtosyslog          = false,
  $globaloptions        = {},
  $globalabsentoptions  = [],
) inherits ::samba::params{


  unless is_integer($idrangemin)
    and is_integer($idrangemax)
    and $idrangemin >= 0
    and $idrangemax >= $idrangemin {
    fail('idrangemin and idrangemax must be integers \
and idrangemin <= idrangemax')
  }

  unless is_domain_name($realm){
    fail('realm must be a valid domain')
  }

  unless is_domain_name($realm){
    fail('realm must be a valid domain')
  }

  unless is_domain_name("${smbname}.${realm}"){
    fail('smbname must be a valid domain')
  }

  $tmparr = split($realm, '[.]')
  unless $domain == $tmparr[0] {
    fail('domain must be the fist part of realm, \
ex: domain="ad" and realm="ad.example.com"')
  }

  $realmDowncase = downcase($realm)
  $globaloptsexclude = concat(keys($globaloptions), $globalabsentoptions)

  file { '/etc/samba/':
    ensure  => 'directory',
  }

  file { '/etc/samba/smb_path':
    ensure  => 'present',
    content => $::samba::params::smbConfFile,
    require => File['/etc/samba/'],
  }

  package{ 'SambaClassic':
    ensure        => 'installed',
    allow_virtual => true,
    name          => $::samba::params::packageSambaClassic,
    require       => File['/etc/samba/smb_path'],
  }

  service{ 'SambaClassic':
    ensure  => 'running',
    name    => $::samba::params::serviveSambaClassic,
    require => [ Package['SambaClassic'], File['SambaOptsFile'] ],
  }

  $sambaMode = 'classic'
  # Deploy /etc/sysconfig/|/etc/defaut/ file (startup options)
  file{ 'SambaOptsFile':
    path    => $::samba::params::sambaOptsFile,
    content => template($::samba::params::sambaOptsTmpl),
    require => Package['SambaClassic'],
  }

  $mandatoryGlobalOptions = {
    'workgroup'                          => $domain,
    'realm'                              => $realm,
    'netbios name'                       => "${smbname}.${realm}",
    'security'                           => 'ADS',
    'dedicated keytab file'              => '/etc/krb5.keytab',
    'winbind nss info'                   => 'rfc2307',
    'map untrusted to domain'            => 'Yes',
    'winbind trusted domains only'       => 'No',
    'winbind use default domain'         => 'Yes',
    'winbind enum users'                 => 'Yes',
    'winbind enum groups'                => 'Yes',
    'winbind refresh tickets'            => 'Yes',
    "idmap config ${domain}:backend"     => 'ad',
    "idmap config ${domain}:schema_mode" => 'rfc2307',
    "idmap config ${domain}:range"       => "${idrangemin}-${idrangemax}",
  }

  $mandatoryGlobalOptionsIndex = prefix(keys($mandatoryGlobalOptions),
    '[global]')
  ::samba::option{ $mandatoryGlobalOptionsIndex:
    options         => $mandatoryGlobalOptions,
    section         => 'global',
    settingsignored => $globaloptsexclude,
    require         => Package['SambaClassic'],
    notify          => Service['SambaClassic'],
  }

  unless $adminpassword == undef {
    exec{ 'Join Domain':
      path    => '/bin:/sbin:/usr/sbin:/usr/bin/',
      unless  => 'net ads testjoin',
      command => "echo '${adminpassword}'| net ads join -U administrator",
    }
  }

  ::samba::log { 'syslog':
    sambaloglevel      => $sambaloglevel,
    logtosyslog        => $logtosyslog,
    sambaclassloglevel => $sambaclassloglevel,
    settingsignored    => $globaloptsexclude,
    require            => Package['SambaClassic'],
    notify             => Service['SambaClassic'],
  }

  # Iteration on global options
  $globaloptionsIndex = prefix(keys($globaloptions), '[globalcustom]')
  ::samba::option{ $globaloptionsIndex:
    options => $globaloptions,
    section => 'global',
    require => Package['SambaClassic'],
    notify  => Service['SambaClassic'],
  }

  resources { 'smb_setting':
    purge => true,
  }

  $gabsoptlist = prefix($globalabsentoptions, 'global/')
  smb_setting { $gabsoptlist :
    ensure  => absent,
    section => 'global',
  }

}

# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
