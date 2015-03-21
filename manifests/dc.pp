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
  $domain		= undef,
  $realm		= undef,
  $dnsbackend		= undef,
  $dnsforwarder		= undef,
  $adminpassword	= undef,
  $ppolicycomplexity	= 'on',
  $ppolicyplaintext	= 'off',
  $ppolicyhistorylength = 24,
  $ppolicyminpwdlength  = 7,
  $ppolicyminpwdage     = 1,
  $ppolicymaxpwdage     = 42,
  $targetdir		= '/var/lib/samba/',
  $domainlevel		= '2003',
  $groups		= [],
  $logonscripts         = [],
  $sambaloglevel        = 1,
  $logtosyslog          = false,
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
        fail('unsupported dns backend, must be in ["internal", "bindFlat", "bindDLZ"]')
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
        fail('unsupported domain level, must be in ["2003", "2008", "2008 R2"]')
    }
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

  unless is_integer($sambaloglevel) and $sambaloglevel >= 0 and $sambaloglevel <= 10{
    fail('loglevel must be an integer between 0 and 10')
  }

  unless is_bool($logtosyslog){
    fail('logtosyslog must be a boolean')
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
  unless "$domain" == $tmparr[0] {
    fail('domain must be the fist part of realm, ex: domain="ad" and realm="ad.example.com"')
  }

  unless $dnsforwarder == undef or is_ip_address($dnsforwarder){
    fail('dns forwarder must be a valid IP address')
  }

  validate_absolute_path($targetdir)

  $realmDowncase = downcase($realm)

  package{ 'SambaDC':
    allow_virtual => true,
    name   => "${::samba::params::packageSambaDC}",
    ensure => 'installed',
  }

  # Provision the Domain Controler
  exec{ 'provisionAD':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    unless  => "test -d '${targetdir}/state/sysvol/$realmDowncase/'",
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

  # Deploy /etc/sysconfig/|/etc/defaut/ file (startup options)
  file{ "SambaOptsFile":
    path    => "${::samba::params::sambaOptsFile}",
    content => template("${::samba::params::sambaOptsTmpl}"),
    require => Package['SambaDC'],
  }

  # Configure Loglevel
  ini_setting { "LogLevel":
    ensure  => present,
    path    => "${::samba::params::smbConfFile}",
    section => 'global',
    setting => 'log level',
    value   => "$sambaloglevel",
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }

  # If specify, configure syslog
  if $logtosyslog {

    ini_setting { "SyslogLogLevel":
      ensure  => present,
      path    => "${::samba::params::smbConfFile}",
      section => 'global',
      setting => 'syslog',
      value   => "$sambaloglevel",
      require => Exec['provisionAD'],
      notify  => Service['SambaDC'],
    }

    ini_setting { "LogToSyslog":
      ensure  => present,
      path    => "${::samba::params::smbConfFile}",
      section => 'global',
      setting => 'syslog only',
      value   => "yes",
      require => Exec['provisionAD'],
      notify  => Service['SambaDC'],
    }
  }
  # If not, keep login ing file, and disable syslog
  else {
    ini_setting { "DontLogToSyslog":
      ensure  => present,
      path    => "${::samba::params::smbConfFile}",
      section => 'global',
      setting => 'syslog only',
      value   => "no",
      require => Exec['provisionAD'],
      notify  => Service['SambaDC'],
    }

    ini_setting { "SyslogLogLevel":
      ensure  => absent,
      path    => "${::samba::params::smbConfFile}",
      section => 'global',
      setting => 'syslog',
      require => Exec['provisionAD'],
      notify  => Service['SambaDC'],
    }


  }

  # Configure dns forwarder 
  # (if not specify, keep the default from provisioning)
  if $dnsforwarder != undef {
    ini_setting { "DnsForwareder":
      ensure  => present,
      path    => "${::samba::params::smbConfFile}",
      section => 'global',
      setting => 'dns forwarder',
      value   => "$dnsforwarder",
      require => Exec['provisionAD'],
      notify  => Service['SambaDC'],
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
    command => "${::samba::params::sambaCmd} domain level raise --domain-level='${domainLevel}'",
    require => Service['SambaDC'],
  }

  # Configure Forest function level
  exec{ 'setForestFunctionLevel':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    unless  => "${::samba::params::sambaCmd} domain level show \
| grep 'Forest function level' | grep -q '${domainlevel}$'",
    command => "${::samba::params::sambaCmd} domain level raise --forest-level='${domainLevel}'",
    require => Exec['setDomainFunctionLevel'],
  }

  # Configure Password Policy
  exec{ 'setPPolicy':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => Service['SambaDC'],
    unless  => "[ \"\$( ${::samba::params::sambaCmd} domain passwordsettings show \
|sed 's/^.*:\\ *\\([0-9]\\+\\|on\\|off\\).*$/\\1/gp;d' | md5sum )\" = \
\"\$( printf '${ppolicycomplexity}\\n${ppolicyplaintext}\\n${ppolicyhistorylength}\
\\n${ppolicyminpwdlength}\\n${ppolicyminpwdage}\\n${ppolicymaxpwdage}\\n' | md5sum )\" ]",
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
  $globaloptionsIndex = range(0, $globaloptionsSize)
  ::samba::option{ $globaloptionsIndex: 
    options => $globaloptions,
    section => 'global',
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }

  # Iteration on netlogon options
  $netlogonoptionsSize  = size($::samba::dc::netlogonoptions) - 1
  $netlogonoptionsIndex = range(0, $netlogonoptionsSize)
  ::samba::option{ $netlogonoptionsIndex: 
    options => $netlogonoptions,
    section => 'netlogon',
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }
 
  # Iteration on sysvol options
  $sysvoloptionsSize  = size($::samba::dc::sysvoloptions) - 1 
  $sysvoloptionsIndex = range(0, $sysvoloptionsSize)
  ::samba::option{ $sysvoloptionsIndex: 
    options => $sysvoloptions,
    section => 'sysvol',
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }
}
