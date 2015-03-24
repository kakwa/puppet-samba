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

class samba::dc(
  $domain               = undef,
  $realm                = undef,
  $dnsbackend           = undef,
  $dnsforwarder         = undef,
  $adminpassword        = undef,
  $role                 = 'dc',
  $ppolicycomplexity    = 'on',
  $ppolicyplaintext     = 'off',
  $ppolicyhistorylength = 24,
  $ppolicyminpwdlength  = 7,
  $ppolicyminpwdage     = 1,
  $ppolicymaxpwdage     = 42,
  $targetdir            = '/var/lib/samba/',
  $domainlevel          = '2003',
  $groups               = [],
  $logonscripts         = [],
  $sambaloglevel        = 1,
  $logtosyslog          = false,
  $sambaclassloglevel   = undef,
  $globaloptions        = [],
  $netlogonoptions      = [],
  $sysvoloptions        = [],
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
      fail('unsupported dns backend, \
must be in ["internal", "bindFlat", "bindDLZ"]')
    }
  }

  case $domainlevel {
    '2003': {
      $domainLevel = '2003'
    }
    '2008': {
      $domainLevel = '2008'
    }
    '2008 R2': {
      $domainLevel = '2008_R2'
    }
    default: {
      fail('unsupported domain level, \
must be in ["2003", "2008", "2008 R2"]')
    }
  }

  # for futur use when samba 4 will support other modes
  #$checkrole = ['dc', 'member', 'standalone']
  $checkrole = ['dc']
  $checkrolestr = join($checkrole, ', ')

  unless member($checkrole, $role){
    fail("role must be in [${checkrolestr}]")
  }

  $checkpp = ['on', 'off', 'default']
  $checkppstr = join($checkpp, ', ')

  unless member($checkpp, $ppolicycomplexity){
    fail("ppolicycomplexity must be in [${checkppstr}]")
  }

  unless member($checkpp, $ppolicyplaintext){
    fail("ppolicyplaintext must be in [${checkppstr}]")
  }

  unless is_integer($ppolicyhistorylength){
    fail('ppolicyhistorylength must be an integer')
  }

  unless is_integer($ppolicyminpwdlength){
    fail('ppolicyminpwdlength must be an integer')
  }

  unless is_integer($ppolicyminpwdage){
    fail('ppolicyminpwdage must be an integer')
  }

  unless is_integer($ppolicymaxpwdage){
    fail('ppolicymaxpwdage must be an integer')
  }

  unless is_domain_name($realm){
    fail('realm must be a valid domain')
  }

  $tmparr = split($realm, '[.]')
  unless $domain == $tmparr[0] {
    fail('domain must be the fist part of realm, \
ex: domain="ad" and realm="ad.example.com"')
  }

  unless $dnsforwarder == undef or is_ip_address($dnsforwarder){
    fail('dns forwarder must be a valid IP address')
  }

  if defined(Service['SambaClassic']){
    fail('Can\'t use samba::dc and samba::classic on the same node')
  }

  validate_absolute_path($targetdir)

  $realmDowncase = downcase($realm)

  $scriptDir = smb_clean_path("${targetdir}/state/sysvol/${realmDowncase}/scripts/")
  validate_absolute_path($scriptDir)

  package{ 'SambaDC':
    ensure        => 'installed',
    allow_virtual => true,
    name          => $::samba::params::packageSambaDC,
  }

  # Provision the Domain Controler
  exec{ 'provisionAD':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    unless  => "test -d '${targetdir}/state/sysvol/$realmDowncase/'",
    command => "printf '' > '${::samba::params::smbConfFile}' && \
${::samba::params::sambaCmd} domain provision \
--domain='${domain}' --realm='${realm}' --dns-backend='$SamaDNS' \
--targetdir='${targetdir}' --workgroup='${domain}' --use-rfc2307 \
--configfile='${::samba::params::smbConfFile}' --server-role='$role' && \
mv '${targetdir}/etc/smb.conf' '${::samba::params::smbConfFile}'",
    require => Package['SambaDC'],
    notify  => Service['SambaDC'],
  }

  service{ 'SambaDC':
    ensure  => 'running',
    name    => $::samba::params::serviveSambaDC,
    require => [ Exec['provisionAD'], File['SambaOptsFile'] ],
  }

  $sambaMode = 'ad'
  # Deploy /etc/sysconfig/|/etc/defaut/ file (startup options)
  file{ 'SambaOptsFile':
    path    => $::samba::params::sambaOptsFile,
    content => template($::samba::params::sambaOptsTmpl),
    require => Package['SambaDC'],
    notify  => Service['SambaDC'],
  }

  # Configure Loglevel
  ::samba::log { 'syslog':
      sambaloglevel      => $sambaloglevel,
      logtosyslog        => $logtosyslog,
      sambaclassloglevel => $sambaclassloglevel,
      require            => Exec['provisionAD'],
      notify             => Service['SambaDC'],
  }

  # Configure dns forwarder
  # (if not specify, keep the default from provisioning)
  if $dnsforwarder != undef {
    smb_setting { 'global/dns forwarder':
      ensure  => present,
      path    => $::samba::params::smbConfFile,
      section => 'global',
      setting => 'dns forwarder',
      value   => $dnsforwarder,
      require => Exec['provisionAD'],
      notify  => Service['SambaDC'],
    }
  } else{
    smb_setting { 'global/dns forwarder':
      ensure  => present,
      section => 'global',
      setting => 'dns forwarder',
    }

  }

  # Check and set administrator password
  exec{ 'setAdminPassword':
    unless  => "${::samba::params::sambaClientCmd} \
//localhost/netlogon ${adminpassword} -UAdministrator  -c 'ls'",
    command => "${::samba::params::sambaCmd} user setpassword \
Administrator --newpassword=${adminpassword}",
    require => Service['SambaDC'],
  }

  # Configure Domain function level
  exec{ 'setDomainFunctionLevel':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    unless  => "${::samba::params::sambaCmd} domain level show \
| grep 'Domain function level' | grep -q \"${domainlevel}$\"",
    command => "${::samba::params::sambaCmd} domain \
level raise --domain-level='${domainLevel}'",
    require => Service['SambaDC'],
  }

  # Configure Forest function level
  exec{ 'setForestFunctionLevel':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    unless  => "${::samba::params::sambaCmd} domain level show \
| grep 'Forest function level' | grep -q '${domainlevel}$'",
    command => "${::samba::params::sambaCmd} domain \
level raise --forest-level='${domainLevel}'",
    require => Exec['setDomainFunctionLevel'],
  }

  # Configure Password Policy
  exec{ 'setPPolicy':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => Service['SambaDC'],

    unless  => "\
[ \"\$( ${::samba::params::sambaCmd} domain passwordsettings show\
|sed 's/^.*:\\ *\\([0-9]\\+\\|on\\|off\\).*$/\\1/gp;d' | md5sum )\" = \
\"\$(printf \
'${ppolicycomplexity}\\n${ppolicyplaintext}\\n${ppolicyhistorylength}\
\\n${ppolicyminpwdlength}\\n${ppolicyminpwdage}\\n${ppolicymaxpwdage}\\n' \
| md5sum )\" ]",

    command => "${::samba::params::sambaCmd} domain passwordsettings set \
--complexity='${ppolicycomplexity}' \
--store-plaintext='${ppolicyplaintext}' \
--history-length='${ppolicyhistorylength}' \
--min-pwd-length='${ppolicyminpwdlength}' \
--min-pwd-age='${ppolicyminpwdage}' \
--max-pwd-age='${ppolicymaxpwdage}'",
  }

  # Iteration to add groups
  $groupSize  = size($::samba::dc::groups) - 1
  $groupIndex = range(0, $groupSize)
  ::samba::dc::groupadd{ $groupIndex: }

  # Iteration to add logon scripts
  $scriptSize  = size($::samba::dc::logonscripts) - 1
  $scriptIndex = range(0, $scriptSize)
  ::samba::dc::scriptadd{ $scriptIndex: }

  # Iteration on global options
  $globaloptionsSize  = size($::samba::dc::globaloptions) - 1
  $globaloptionsIndex = prefix(range(0, $globaloptionsSize), 'globalcut:')
  ::samba::option{ $globaloptionsIndex:
    options => $globaloptions,
    section => 'global',
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }

  # Iteration on netlogon options
  $netlogonoptionsSize  = size($::samba::dc::netlogonoptions) - 1
  #$netlogonoptionsIndex = range(0, $netlogonoptionsSize)
  $netlogonoptionsIndex = prefix(range(0, $netlogonoptionsSize),
    'netlogoncust:')
  ::samba::option{ $netlogonoptionsIndex:
    options => $netlogonoptions,
    section => 'netlogon',
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }

  # Iteration on sysvol options
  $sysvoloptionsSize  = size($::samba::dc::sysvoloptions) - 1
  $sysvoloptionsIndex = prefix(range(0, $sysvoloptionsSize), 'sysvolcust:')
  ::samba::option{ $sysvoloptionsIndex:
    options => $sysvoloptions,
    section => 'sysvol',
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }

  $mandatoryGlobalOptions = [
    {setting => 'workgroup',              value => $domain},
    {setting => 'realm',                  value => $realm},
    {setting => 'netbios name',           value => 'AD'},
    {setting => 'server role',            value => 'active directory domain controller'},
    {setting => 'private dir',            value => smb_clean_path("${targetdir}/private/")},
    {setting => 'cache directory',        value => smb_clean_path("${targetdir}/cache/")},
    {setting => 'state directory',        value => smb_clean_path("${targetdir}/state/")},
    {setting => 'lock directory',         value => smb_clean_path("${targetdir}/")},
    {setting => 'idmap_ldb:use rfc2307',  value => 'Yes'},
  ]

  $mandatoryGlobalOptionsSize  = size($mandatoryGlobalOptions) - 1
  $mandatoryGlobalOptionsIndex = prefix(range(0,
    $mandatoryGlobalOptionsSize), 'global:')
  ::samba::option{ $mandatoryGlobalOptionsIndex:
    options => $mandatoryGlobalOptions,
    section => 'global',
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }

  $mandatorySysvolOptions = [
    {setting => 'path',              value => smb_clean_path("${targetdir}/state/sysvol")},
    {setting => 'read only',         value => 'No'},
  ]

  $mandatorySysvolOptionsSize  = size($mandatorySysvolOptions) - 1
  $mandatorySysvolOptionsIndex = prefix(range(0,
  $mandatorySysvolOptionsSize), 'sysvol:')
  ::samba::option{ $mandatorySysvolOptionsIndex:
    options => $mandatorySysvolOptions,
    section => 'sysvol',
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }

  $mandatoryNetlogonOptions = [
    {setting => 'path',              value => $scriptDir},
    {setting => 'read only',         value => 'No'},
  ]

  $mandatoryNetlogonOptionsSize  = size($mandatoryNetlogonOptions) - 1
  $mandatoryNetlogonOptionsIndex = prefix(range(0,
  $mandatoryNetlogonOptionsSize), 'netlogon:')
  ::samba::option{ $mandatoryNetlogonOptionsIndex:
    options => $mandatoryNetlogonOptions,
    section => 'netlogon',
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }

  resources { 'smb_setting':
    purge => true,
  }

}

# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
