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

define samba::dc::dnszone(
  String $zone                 = undef,
) {

  exec { "dnszone ${title}":
    path    => '/bin:/usr/sbin:/usr/bin',
    unless  => "samba-tool dns zonelist -P localhost | egrep \"pszZoneName(\s)+:(\s+)${zone}\"",
    command => "samba-tool dns zonecreate -P localhost ${zone}",
  }

  Service['SambaDC'] -> Samba::Dc::Dnszone<| |>
}

# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
