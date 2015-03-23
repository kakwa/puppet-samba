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
  $logtosyslog          = false,
  $globaloptions        = [],
) inherits ::samba::params{

  unless is_integer($sambaloglevel)
    and $sambaloglevel >= 0
    and $sambaloglevel <= 10{
    fail('loglevel must be an integer between 0 and 10')
  }

  unless is_integer($idrangemin)
    and is_integer($idrangemax)
    and $idrangemin >= 0
    and $idrangemax >= $idrangemin {
    fail("idrangemin and idrangemax must be integers \
and idrangemin <= idrangemax")
  }

  unless is_bool($logtosyslog){
    fail('logtosyslog must be a boolean')
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
    #name    => [ 'sernet-samba-smbd', 'sernet-samba-winbindd' ],
    require => [ Package['SambaClassic'], File['SambaOptsFile'] ],
  }

  $sambaMode = 'classic'
  # Deploy /etc/sysconfig/|/etc/defaut/ file (startup options)
  file{ 'SambaOptsFile':
    path    => $::samba::params::sambaOptsFile,
    content => template($::samba::params::sambaOptsTmpl),
    require => Package['SambaClassic'],
  }

  $mandatoryGlobalOptions = [
   {setting => 'workgroup',                          value => "$domain"},
   {setting => 'realm',                              value => "$realm"},
   {setting => 'netbios name',                       value => "${smbname}.${realm}"},
   {setting => 'security',                           value => 'ADS'},
   {setting => 'dedicated keytab file',              value => '/etc/krb5.keytab'},
   {setting => 'winbind nss info',                   value => 'rfc2307'},
   {setting => 'map untrusted to domain',            value => 'Yes'},
   {setting => 'winbind trusted domains only',       value => 'No'},
   {setting => 'winbind use default domain',         value => 'Yes'},
   {setting => 'winbind enum users',                 value => 'Yes'},
   {setting => 'winbind enum groups',                value => 'Yes'},
   {setting => 'winbind refresh tickets',            value => 'Yes'},
   {setting => "idmap config ${domain}:backend",     value => 'ad'},
   {setting => "idmap config ${domain}:schema_mode", value => 'rfc2307'},
   {setting => "idmap config ${domain}:range",       value => "${idrangemin}-${idrangemax}"},
  ]

  $mandatoryGlobalOptionsSize  = size($mandatoryGlobalOptions) - 1
  $mandatoryGlobalOptionsIndex = range(0, $mandatoryGlobalOptionsSize)
  ::samba::option{ $mandatoryGlobalOptionsIndex:
    options => $mandatoryGlobalOptions,
    section => 'global',
    require => Package['SambaClassic'],
    notify  => Service['SambaClassic'],
  }

  # Configure Loglevel
  smb_setting { 'global/log level':
    ensure  => present,
    path    => $::samba::params::smbConfFile,
    section => 'global',
    setting => 'log level',
    value   => $sambaloglevel,
    require => Package['SambaClassic'],
    notify  => Service['SambaClassic'],
  }

  # If specify, configure syslog
  if $logtosyslog {
    smb_setting { 'global/syslog':
      ensure  => present,
      path    => $::samba::params::smbConfFile,
      section => 'global',
      setting => 'syslog',
      value   => $sambaloglevel,
      require => Package['SambaClassic'],
      notify  => Service['SambaClassic'],
    }

    smb_setting { 'global/syslog only':
      ensure  => present,
      path    => $::samba::params::smbConfFile,
      section => 'global',
      setting => 'syslog only',
      value   => 'yes',
      require => Package['SambaClassic'],
      notify  => Service['SambaClassic'],
    }
  }
  # If not, keep login ing file, and disable syslog
  else {
    smb_setting { 'global/syslog only':
      ensure  => present,
      path    => $::samba::params::smbConfFile,
      section => 'global',
      setting => 'syslog only',
      value   => 'no',
      require => Package['SambaClassic'],
      notify  => Service['SambaClassic'],
    }

    smb_setting { 'global/syslog':
      ensure  => absent,
      path    => $::samba::params::smbConfFile,
      section => 'global',
      setting => 'syslog',
      require => Package['SambaClassic'],
      notify  => Service['SambaClassic'],
    }
  }

  # Iteration on global options
  $globaloptionsSize  = size($::samba::classic::globaloptions) - 1
  $globaloptionsIndex = range(0, $globaloptionsSize)
  ::samba::option{ $globaloptionsIndex:
    options => $globaloptions,
    section => 'global',
    require => Package['SambaClassic'],
    notify  => Service['SambaClassic'],
    purge => true,
  }

  resources { 'smb_setting':
    purge => true,
  } 

}

# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
