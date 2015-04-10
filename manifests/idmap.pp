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

define samba::idmap(
  $domain               = undef,
  $idrangemin           = undef,
  $idrangemax           = undef,
  $backend              = undef,
  $schema_mode          = undef,
  $rangesize            = 100000,
  $read_only            = 'no',
  $ignore_builtin       = 'no',
  $name_map             = undef,
  $ldap_base_dn         = undef,
  $ldap_user_dn         = undef,
  $ldap_url             = undef,
  $ldap_passwd          = undef,
  $script               = undef,
) inherits ::samba::params{


  unless is_integer($idrangemin)
    and is_integer($idrangemax)
    and $idrangemin >= 0
    and $idrangemax >= $idrangemin {
    fail('idrangemin and idrangemax must be integers \
and idrangemin <= idrangemax')
  }

  unless $domain{
    fail('domain must be a valid domain or *')
  }

  $checkbackend = ['ad', 'autorid', 'hash', 'ldap', 'nss', 'rid', 'tdb2', 'tdb']
  $checkbackendstr = join($checkbackend, ', ')

  unless member($checkbackend, downcase($backend)){
    fail("role must be in [${checkbackendstr}]")
  } 
  
  $cp = "idmap config ${domain} :"

  case $backend {
   'ad': {
      unless $schema_mode {
        fail("missing parameter(s) for idmap_${backend}, need: schema_mode")
      }
      $idmap_specific = {
	"${cp} schema_mode" => $schema_mode,
      }
   }
   'autorid': {
      unless $rangesize and $read_only and $ignore_builtin {
        fail("missing parameter(s) for idmap_${backend} need: rangesize, read_only, ignore_builtin")
      }
      $idmap_specific = {
	"${cp} rangesize"      => $rangesize,
	"${cp} read only"      => $read_only,
	"${cp} ignore builtin" => $ignore_builtin,
      }
   }
   'hash': {
      unless $name_map{
        fail("missing parameter(s) for idmap_${backend} need: name_map")
      }
      $idmap_specific = {
        "idmap_hash:name_map" => $name_map,
      }
   }
   'ldap': {
      unless $ldap_base_dn and $ldap_user_dn and $ldap_url and $ldap_passwd {
        fail("missing parameter(s) for idmap_${backend} need: ldap_base_dn, ldap_user_dn, ldap_url, ldap_passwd")
      }
      $idmap_specific = {
	"${cp} ldap_base_dn" => $ldap_base_dn,
	"${cp} ldap_user_dn" => $ldap_user_dn,
	"${cp} ldap_url"     => $ldap_url,
      }
      exec { 'set ldap passwd':
        cmd     => "/bin/false $ldap_passwd",
        require => Service['SambaClassic'],
      }
      #'ldap_passwd' => $ignore_builtin,
   }
   'nss': {
      $idmap_specific = {}
   }
   'rid': {
      $idmap_specific = {}
   }
   'tdb2': {
      $idmap_specific = {
        "${cp} script" => $script,
      }
   }
   'tdb': {
      $idmap_specific = {}
   }
  }

  $idmap_base = {
    "${cp} backend"     => $backend,
    "${cp} range"       => "${idrangemin}-${idrangemax}",
  }

  $merged = merge($idmap_base, $idmap_specific)

  $idmapOptionsIndex = prefix(keys($idmapOptions),
    '[global]')
  ::samba::option{ $idmapOptionsIndex:
    options         => $idmapOptions,
    section         => 'global',
    require         => Package['SambaClassic'],
    notify          => Service['SambaClassic'],
  }
}

# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
