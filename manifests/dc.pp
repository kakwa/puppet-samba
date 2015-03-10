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

class  samba::dc(
  $domain     = undef,
  $realm      = undef,
  $dnsbackend = undef,
  $adminpassword = undef,
  $targetdir = '/var/lib/samba/'
) inherits ::samba::params{

  case $dnsbackend {
    'internal': {
        $SamaDNS   = 'SAMBA_INTERNAL' 
    }
    'bindFlat': {
        $SamaDNS   = 'BIND9_FLATFILE' 
    }
    'bindDLZ': {
        $SamaDNS   = 'BIND9_FLATFILE' 
    }
    default: {
        fail('unsupported dns backend, must be in [internal, bindFlat, bindDLZ]')
    }
  }

  package{ 'SambaDC':
    allow_virtual => true,
    name   => "${::samba::params::packageSambaDC}",
    ensure => 'installed',
  }

  exec{ 'provisionAD':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    unless  => "[ `find '${targetdir}/state/sysvol/' -iname '${realm}' | wc -l` -ne 0 ]",
    command => "printf '' > '${::samba::params::smbConfFile}' && \
${::samba::params::sambaCmd} domain provision \
--domain='${domain}' --realm='${realm}' --dns-backend='$SamaDNS' \
--targetdir='${targetdir}' --workgroup='${domain}' --use-rfc2307 \
--configfile='${::samba::params::smbConfFile}' && \
mv '${targetdir}/etc/smb.conf' '${::samba::params::smbConfFile}'",
    require => Package['SambaDC'],
    notify  => Service['SambaDC'],
  }

  service{ 'SambaDC':
    ensure => 'running',
    name   => "${::samba::params::serviveSambaDC}",
    require => [ Exec['provisionAD'], File['SambaOptsFile'] ],
  }

  file{ "SambaOptsFile":
    path    => "${::samba::params::sambaOptsFile}",
    content => template("${::samba::params::sambaOptsTmpl}"),
    require => Package['SambaDC'],
  }

  exec{ 'setAdminPassword':
    unless  => "${::samba::params::sambaClientCmd} \
//localhost/netlogon ${adminpassword} -UAdministrator  -c 'ls'",
    command => "${::samba::params::sambaCmd} user setpassword \
Administrator --newpassword=${adminpassword}",
    require => Service['SambaDC'],
  }

}
