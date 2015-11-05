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
  $strictrealm          = true,
  $adminuser            = 'administrator',
  $adminpassword        = undef,
  $security             = 'ads',
  $sambaloglevel        = 1,
  $krbconf              = true,
  $nsswitch             = true,
  $sambaclassloglevel   = undef,
  $logtosyslog          = false,
  $globaloptions        = {},
  $globalabsentoptions  = [],
  $joinou               = undef,
) inherits ::samba::params{


  unless is_domain_name($realm){
    fail('realm must be a valid domain')
  }

  unless is_domain_name($realm){
    fail('realm must be a valid domain')
  }

  validate_slength($smbname, 15)
  unless is_domain_name("${smbname}.${realm}"){
    fail('smbname must be a valid domain')
  }

  if $strictrealm {
    $tmparr = split($realm, '[.]')
    unless $domain == $tmparr[0] {
      fail('domain must be the fist part of realm, ex: domain="ad" and realm="ad.example.com"')
    }
  }

  $checksecurity = ['ads', 'auto', 'user', 'domain']
  $checksecuritystr = join($checksecurity, ', ')

  unless member($checksecurity, downcase($security)){
    fail("role must be in [${checksecuritystr}]")
  }

  $realmlowercase = downcase($realm)
  $realmuppercase = upcase($realm)
  $globaloptsexclude = concat(keys($globaloptions), $globalabsentoptions)

  file { '/etc/samba/':
    ensure  => 'directory',
  }

  file { '/etc/samba/smb_path':
    ensure  => 'present',
    content => $::samba::params::smbconffile,
    require => File['/etc/samba/'],
  }

  if $krbconf {
    file {$::samba::params::krbconffile:
      ensure  => present,
      mode    => '0644',
      content => template("${module_name}/krb5.conf.erb"),
      notify  => Service['SambaSmb', 'SambaWinBind'],
    }
  }

  if $nsswitch {
    augeas{'samba nsswitch group':
      context => "/files/${::samba::params::nsswitchconffile}/",
      changes => [
        'ins service after "*[self::database = \'group\']/service[1]/"',
        'set "*[self::database = \'group\']/service[2]" winbind',
      ],
      onlyif  => 'get "*[self::database = \'group\']/service[2]" != winbind',
      lens    => 'Nsswitch.lns',
      incl    => $::samba::params::nsswitchconffile,
    }
    augeas{'samba nsswitch passwd':
      context => "/files/${::samba::params::nsswitchconffile}/",
      changes => [
        'ins service after "*[self::database = \'passwd\']/service[1]/"',
        'set "*[self::database = \'passwd\']/service[2]" winbind',
      ],
      onlyif  => 'get "*[self::database = \'passwd\']/service[2]" != winbind',
      lens    => 'Nsswitch.lns',
      incl    => $::samba::params::nsswitchconffile,
    }
  }

  package{ 'SambaClassicWinBind':
    ensure  => 'installed',
    name    => $::samba::params::packagesambawinbind,
    require => File['/etc/samba/smb_path'],
  }

  package{ 'SambaClassic':
    ensure  => 'installed',
    name    => $::samba::params::packagesambaclassic,
    require => Package['SambaClassicWinBind'],
  }

  service{ 'SambaSmb':
    ensure  => 'running',
    name    => $::samba::params::servivesmb,
    require => [ Package['SambaClassic'], File['SambaOptsFile'] ],
  }

  service{ 'SambaWinBind':
    ensure  => 'running',
    name    => $::samba::params::servivewinbind,
    require => [ Package['SambaClassic'], File['SambaOptsFile'] ],
  }

  $sambamode = 'classic'
  # Deploy /etc/sysconfig/|/etc/defaut/ file (startup options)
  file{ 'SambaOptsFile':
    path    => $::samba::params::sambaoptsfile,
    content => template($::samba::params::sambaoptstmpl),
    require => Package['SambaClassic'],
  }

  $mandatoryglobaloptions = {
    'workgroup'                          => $domain,
    'realm'                              => $realm,
    'netbios name'                       => $smbname,
    'security'                           => $security,
    'dedicated keytab file'              => '/etc/krb5.keytab',
    'vfs objects'                        => 'acl_xattr',
    'map acl inherit'                    => 'Yes',
    'store dos attributes'               => 'Yes',
    'map untrusted to domain'            => 'Yes',
    'winbind nss info'                   => 'rfc2307',
    'winbind trusted domains only'       => 'No',
    'winbind use default domain'         => 'Yes',
    'winbind enum users'                 => 'Yes',
    'winbind enum groups'                => 'Yes',
    'winbind refresh tickets'            => 'Yes',
    'winbind separator'                  => '+',
  }

  file{ 'SambaCreateHome':
    path   => $::samba::params::sambacreatehome,
    source => "puppet:///modules/${module_name}/smb-create-home.sh",
    mode   => '0755',
  }

  $mandatoryglobaloptionsindex = prefix(keys($mandatoryglobaloptions),
    '[global]')
  ::samba::option{ $mandatoryglobaloptionsindex:
    options         => $mandatoryglobaloptions,
    section         => 'global',
    settingsignored => $globaloptsexclude,
    require         => Package['SambaClassic'],
    notify          => Service['SambaSmb', 'SambaWinBind'],
  }

  ::samba::log { 'syslog':
    sambaloglevel      => $sambaloglevel,
    logtosyslog        => $logtosyslog,
    sambaclassloglevel => $sambaclassloglevel,
    settingsignored    => $globaloptsexclude,
    require            => Package['SambaClassic'],
    notify             => Service['SambaSmb', 'SambaWinBind'],
  }

  # Iteration on global options
  $globaloptionsindex = prefix(keys($globaloptions), '[globalcustom]')
  ::samba::option{ $globaloptionsindex:
    options => $globaloptions,
    section => 'global',
    require => Package['SambaClassic'],
    notify  => Service['SambaSmb', 'SambaWinBind'],
  }

  resources { 'smb_setting':
    purge => true,
  }

  $gabsoptlist = prefix($globalabsentoptions, 'global/')
  smb_setting { $gabsoptlist :
    ensure  => absent,
    section => 'global',
    require => Package['SambaClassic'],
    notify  => Service['SambaSmb', 'SambaWinBind'],
  }

  unless $adminpassword == undef {
    $ou = $joinou ? {
      default => "createcomputer=\"${joinou}\"",
      undef   => '',
    }
    exec{ 'Join Domain':
      path    => '/bin:/sbin:/usr/sbin:/usr/bin/',
      unless  => 'net ads testjoin',
      command => "echo '${adminpassword}'| net ads join -U '${adminuser}' ${ou}",
      notify  => Service['SambaWinBind'],
      require => [ Package['SambaClassic'], Service['SambaSmb'] ],
    }
  }
}

# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
