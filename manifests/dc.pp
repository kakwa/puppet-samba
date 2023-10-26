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
  $domain                                                         = undef,
  $realm                                                          = undef,
  $dnsbackend                                                     = 'internal',
  Optional[Stdlib::Ip_address] $dnsforwarder                      = undef,
  $adminpassword                                                  = undef,
  $role                                                           = 'dc',
  Stdlib::Absolutepath $targetdir                                 = '/var/lib/samba/',
  Enum['2003', '2008', '2008 R2', '2012', '2012 R2'] $domainlevel = '2003',
  $domainprovargs                                                 = '',
  $sambaloglevel                                                  = 1,
  $ip                                                             = undef,
  $logtosyslog                                                    = false,
  $sambaclassloglevel                                             = undef,
  $globaloptions                                                  = {},
  $netlogonoptions                                                = {},
  $sysvoloptions                                                  = {},
  $globalabsentoptions                                            = [],
  $netlogonabsentoptions                                          = [],
  $sysvolabsentoptions                                            = [],
  Optional[String] $cleanup                                       = undef,
) inherits ::samba::params{

  case $dnsbackend {
    'internal': {
      $sambadns   = 'SAMBA_INTERNAL'
    }
    'bindFlat': {
      $sambadns   = 'BIND9_FLATFILE'
    }
    'bindDLZ': {
      $sambadns   = 'BIND9_DLZ'
    }
    default: {
      fail('unsupported dns backend, \
must be in ["internal", "bindFlat", "bindDLZ"]')
    }
  }

  case $domainlevel {
    '2003': {
      $strdomainlevel = '2003'
    }
    '2008': {
      $strdomainlevel = '2008'
    }
    '2008 R2': {
      $strdomainlevel = '2008_R2'
    }
    '2012': {
      $strdomainlevel = '2012'
    }
    '2012 R2': {
      $strdomainlevel = '2012_R2'
    }
    default: {
      fail('unsupported domain level, must be in ["2003", "2008", "2008 R2", "2012", "2012 R2"]')
    }
  }

  # for futur use when samba 4 will support other modes
  #$checkrole = ['dc', 'member', 'standalone']
  $checkrole = ['dc']
  $checkrolestr = join($checkrole, ', ')

  unless member($checkrole, $role){
    fail("role must be in [${checkrolestr}]")
  }

  unless ($realm =~ Variant[Stdlib::Fqdn, Stdlib::Dns::Zone]) {
    fail('realm must be a valid domain')
  }

  $tmparr = split($realm, '[.]')
  unless $domain == $tmparr[0] {
    fail('domain must be the fist part of realm, \
ex: domain="ad" and realm="ad.example.com"')
  }

  if defined(Service['SambaSmb']) or defined(Service['SambaWinBind']){
    fail('Can\'t use samba::dc and samba::classic on the same node')
  }

  if $ip {
    if is_ipv4($ip){
      $hostip="--host-ip='${ip}'"
    }
    elsif is_ipv6($ip){
      $hostip="--host-ip6='${ip}'"
    }
    else{
      fail('ip must be a valid IP v4/v6 address, or kept undef')
    }
  }
  else{
    $hostip=''
  }

  $realmdowncase = downcase($realm)

  $scriptdir = smb_clean_path(
    "${targetdir}/state/sysvol/${realmdowncase}/scripts/"
  )
  assert_type(Stdlib::Absolutepath, $scriptdir)

  $globaloptsexclude   = concat(keys($globaloptions), $globalabsentoptions)
  $netlogonoptsexclude = concat(keys($netlogonoptions), $netlogonabsentoptions)
  $sysvoloptsexclude   = concat(keys($sysvoloptions), $sysvolabsentoptions)

  file { '/etc/samba/':
    ensure  => 'directory',
  }

  file { '/etc/samba/smb_path':
    ensure  => 'present',
    content => $::samba::params::smbconffile,
    require => File['/etc/samba/'],
  }

  package{ 'SambaWinBind':
    ensure  => 'installed',
    name    => $::samba::params::packagesambawinbind,
    require => File['/etc/samba/smb_path'],
  }

  package{ 'SambaClient':
    ensure  => 'installed',
    name    => $::samba::params::packagesambaclient,
    require => File['/etc/samba/smb_path'],
  }

  package{ 'SambaDC':
    ensure  => 'installed',
    name    => $::samba::params::packagesambadc,
    require => Package['SambaClient', 'SambaWinBind'],
  }

  service{ 'SambaClassic':
    ensure  => 'stopped',
    name    => $::samba::params::servivesmb,
    enable  => false,
    require => Package['SambaDC'],
    notify  => Service['SambaDC'],
  }

  # it's ugly but this should only run in case of an initial provisioning.
  # the debian package and the init script in debian are a bit crappy and
  # don't track the processes properly and start the samba service by
  # default
  if $cleanup {
    exec{ 'CleanService':
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      unless  => "test -d '${targetdir}/state/sysvol/${realmdowncase}/'",
      command => $cleanup,
      require => Package['SambaDC'],
      before  => Exec['provisionAD'],
      notify  => Service['SambaDC'],
    }
  }

  # Provision the Domain Controler
  exec{ 'provisionAD':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    unless  => "test -d '${targetdir}/state/sysvol/${realmdowncase}/'",
    command => "printf '' > '${::samba::params::smbconffile}' && \
${::samba::params::sambacmd} domain provision ${hostip} \
--domain='${domain}' --realm='${realm}' --dns-backend='${sambadns}' \
--targetdir='${targetdir}' --use-rfc2307 \
--configfile='${::samba::params::smbconffile}' --server-role='${role}' ${domainprovargs} -d 1 && \
mv '${targetdir}/etc/smb.conf' '${::samba::params::smbconffile}'",
    notify  => Service['SambaDC'],
  }

  service{ 'SambaDC':
    ensure  => 'running',
    name    => $::samba::params::servivesambadc,
    require => [ Exec['provisionAD'], File['SambaOptsFile'] ],
    enable  => true,
  }

  $sambamode = 'ad'
  # Deploy /etc/sysconfig/|/etc/defaut/ file (startup options)
  file{ 'SambaOptsFile':
    path    => $::samba::params::sambaoptsfile,
    content => template($::samba::params::sambaoptstmpl),
    require => Package['SambaDC'],
    notify  => Service['SambaDC'],
  }

  package{ 'PyYaml':
    ensure => 'installed',
    name   => $::samba::params::packagepyyaml,
  }

  file{ 'SambaOptsAdditionnalTool':
    path    => $::samba::params::sambaaddtool,
    source  => "puppet:///modules/${module_name}/additional-samba-tool",
    mode    => '0755',
    require => Package['PyYaml'],
  }

  # Configure Loglevel
  ::samba::log { 'syslog':
    sambaloglevel      => $sambaloglevel,
    logtosyslog        => $logtosyslog,
    sambaclassloglevel => $sambaclassloglevel,
    settingsignored    => $globaloptsexclude,
    require            => Exec['provisionAD'],
    notify             => Service['SambaDC'],
  }

  # Configure dns forwarder
  # (if not specify, keep the default from provisioning)
  unless member($globaloptsexclude , 'dns forwarder'){
    if $dnsforwarder != undef {
      smb_setting { 'global/dns forwarder':
        ensure  => present,
        path    => $::samba::params::smbconffile,
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
  }

  # Check and set administrator password
  unless $adminpassword == undef {
    exec{ 'setAdminPassword':
      unless  => "${::samba::params::sambaclientcmd} \
//localhost/netlogon ${adminpassword} -Uadministrator  -c 'ls'",
      command => "${::samba::params::sambacmd} user setpassword \
Administrator --newpassword=${adminpassword} -d 1",
      require => Service['SambaDC'],
    }
  }

  # Configure Domain function level
  exec{ 'setDomainFunctionLevel':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    unless  => "${::samba::params::sambacmd} domain level show  -d 1\
| grep 'Domain function level' | grep -q \"${domainlevel}$\"",
    command => "${::samba::params::sambacmd} domain \
level raise --domain-level='${domainlevel}' -d 1",
    require => Service['SambaDC'],
  }

  # Configure Forest function level
  exec{ 'setForestFunctionLevel':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    unless  => "${::samba::params::sambacmd} domain level show -d 1\
| grep 'Forest function level' | grep -q '${domainlevel}$'",
    command => "${::samba::params::sambacmd} domain \
level raise --forest-level='${domainlevel}' -d 1",
    require => Exec['setDomainFunctionLevel'],
  }

  # Iteration on global options
  $globaloptionsindex = prefix(keys($globaloptions), '[globalcust]')
  ::samba::option{ $globaloptionsindex:
    options => $globaloptions,
    section => 'global',
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }

  # Iteration on netlogon options
  $netlogonoptionsindex = prefix(keys($netlogonoptions), '[netlogoncust]')
  ::samba::option{ $netlogonoptionsindex:
    options => $netlogonoptions,
    section => 'netlogon',
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }

  # Iteration on sysvol options
  $sysvoloptionsindex = prefix(keys($sysvoloptions), '[sysvolcust]')
  ::samba::option{ $sysvoloptionsindex:
    options => $sysvoloptions,
    section => 'sysvol',
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }

  $mandatoryglobaloptions = {
    'workgroup'             => $domain,
    'realm'                 => $realm,
    'netbios name'          => upcase($facts['hostname']),
    'server role'           => 'active directory domain controller',
    'private dir'           => smb_clean_path("${targetdir}/private/"),
    'cache directory'       => smb_clean_path("${targetdir}/cache/"),
    'state directory'       => smb_clean_path("${targetdir}/state/"),
    'lock directory'        => smb_clean_path("${targetdir}/"),
    'idmap_ldb:use rfc2307' => 'Yes',
  }

  $mandatoryglobaloptionsindex = prefix(keys($mandatoryglobaloptions),
    '[global]')
  ::samba::option{ $mandatoryglobaloptionsindex:
    options         => $mandatoryglobaloptions,
    section         => 'global',
    settingsignored => $globaloptsexclude,
    require         => Exec['provisionAD'],
    notify          => Service['SambaDC'],
  }

  $mandatorysysvoloptions = {
    'path'      => smb_clean_path("${targetdir}/state/sysvol"),
    'read only' => 'No',
  }

  $mandatorysysvoloptionsindex = prefix(keys($mandatorysysvoloptions),
    '[sysvol]')
  ::samba::option{ $mandatorysysvoloptionsindex:
    options         => $mandatorysysvoloptions,
    section         => 'sysvol',
    settingsignored => $sysvoloptsexclude,
    require         => Exec['provisionAD'],
    notify          => Service['SambaDC'],
  }

  $mandatorynetlogonoptions = {
    'path'      => $scriptdir,
    'read only' => 'No',
  }

  $mandatorynetlogonoptionsindex = prefix(keys(
  $mandatorynetlogonoptions), '[netlogon]')
  ::samba::option{ $mandatorynetlogonoptionsindex:
    options         => $mandatorynetlogonoptions,
    section         => 'netlogon',
    settingsignored => $netlogonoptsexclude,
    require         => Exec['provisionAD'],
    notify          => Service['SambaDC'],
  }

  file{ 'SambaCreateHome':
    path   => $::samba::params::sambacreatehome,
    source => "puppet:///modules/${module_name}/smb-create-home.sh",
    mode   => '0755',
  }

  $gabsoptlist = prefix($globalabsentoptions, 'global/')
  smb_setting { $gabsoptlist :
    ensure  => absent,
    section => 'global',
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],

  }

  $sabsoptlist = prefix($sysvolabsentoptions, 'sysvol/')
  smb_setting { $sabsoptlist :
    ensure  => absent,
    section => 'sysvol',
  }

  $nabsoptlist = prefix($netlogonabsentoptions, 'netlogon/')
  smb_setting { $nabsoptlist :
    ensure  => absent,
    section => 'netlogon',
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }

  resources { 'smb_setting':
    purge   => true,
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }
}

# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
