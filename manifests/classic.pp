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
  $domain               = undef,
  $realm                = undef,
  $adminpassword        = undef,
  $sambaloglevel        = 1,
  $logtosyslog          = false,
  $globaloptions        = [],
) inherits ::samba::params{

  unless is_integer($sambaloglevel)
    and $sambaloglevel >= 0
    and $sambaloglevel <= 10{
    fail('loglevel must be an integer between 0 and 10')
  }

  unless is_bool($logtosyslog){
    fail('logtosyslog must be a boolean')
  }

  unless is_domain_name($realm){
    fail('realm must be a valid domain')
  }

  $tmparr = split($realm, '[.]')
  unless $domain == $tmparr[0] {
    fail('domain must be the fist part of realm, \
ex: domain="ad" and realm="ad.example.com"')
  }

  $realmDowncase = downcase($realm)

  package{ 'SambaClassic':
    ensure        => 'installed',
    allow_virtual => true,
    name          => $::samba::params::packageSambaClassic,
  }

  service{ 'SambaClassic':
    ensure  => 'running',
    name    => $::samba::params::serviveSambaClassic,
    require => [ Exec['provisionAD'], File['SambaOptsFile'] ],
  }

  $sambaMode = 'classic'
  # Deploy /etc/sysconfig/|/etc/defaut/ file (startup options)
  file{ 'SambaOptsFile':
    path    => $::samba::params::sambaOptsFile,
    content => template($::samba::params::sambaOptsTmpl),
    require => Package['SambaClassic'],
  }

  # Configure Loglevel
  ini_setting { 'LogLevel':
    ensure  => present,
    path    => $::samba::params::smbConfFile,
    section => 'global',
    setting => 'log level',
    value   => $sambaloglevel,
    require => Exec['provisionAD'],
    notify  => Service['SambaClassic'],
  }

  # If specify, configure syslog
  if $logtosyslog {
    ini_setting { 'SyslogLogLevel':
      ensure  => present,
      path    => $::samba::params::smbConfFile,
      section => 'global',
      setting => 'syslog',
      value   => $sambaloglevel,
      require => Exec['provisionAD'],
      notify  => Service['SambaClassic'],
    }

    ini_setting { 'LogToSyslog':
      ensure  => present,
      path    => $::samba::params::smbConfFile,
      section => 'global',
      setting => 'syslog only',
      value   => 'yes',
      require => Exec['provisionAD'],
      notify  => Service['SambaClassic'],
    }
  }
  # If not, keep login ing file, and disable syslog
  else {
    ini_setting { 'DontLogToSyslog':
      ensure  => present,
      path    => $::samba::params::smbConfFile,
      section => 'global',
      setting => 'syslog only',
      value   => 'no',
      require => Exec['provisionAD'],
      notify  => Service['SambaClassic'],
    }

    ini_setting { 'SyslogLogLevel':
      ensure  => absent,
      path    => $::samba::params::smbConfFile,
      section => 'global',
      setting => 'syslog',
      require => Exec['provisionAD'],
      notify  => Service['SambaClassic'],
    }
  }

  # Configure dns forwarder
  # (if not specify, keep the default from provisioning)
  if $dnsforwarder != undef {
    ini_setting { 'DnsForwareder':
      ensure  => present,
      path    => $::samba::params::smbConfFile,
      section => 'global',
      setting => 'dns forwarder',
      value   => $dnsforwarder,
      require => Exec['provisionAD'],
      notify  => Service['SambaClassic'],
    }
  }

  # Iteration on global options
  $globaloptionsSize  = size($::samba::dc::globaloptions) - 1
  $globaloptionsIndex = range(0, $globaloptionsSize)
  ::samba::option{ $globaloptionsIndex:
    options => $globaloptions,
    section => 'global',
    require => Exec['provisionAD'],
    notify  => Service['SambaClassic'],
  }

}

# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
