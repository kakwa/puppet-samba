define samba::log(
  $sambaloglevel,
  $logtosyslog,
  $sambaclassloglevel = undef,
) {

  unless is_integer($sambaloglevel)
    and $sambaloglevel >= 0
    and $sambaloglevel <= 10{
    fail('loglevel must be an integer between 0 and 10')
  }

  $classlist = $::samba::params::logclasslist
  $classliststr = join($classlist, ', ')


  if $sambaclassloglevel != undef {
    unless is_hash($sambaclassloglevel)
    and difference(keys($sambaclassloglevel), $classlist) == [] {
      fail("sambaclassloglevel must be a hash with keys in [${classliststr}]")
    }
    $logadditional = template("${module_name}/log.erb")
  }else {
    $logadditional = ''
  }
  unless is_bool($logtosyslog){
    fail('logtosyslog must be a boolean')
  }

  # Configure Loglevel
  smb_setting { 'global/log level':
    ensure  => present,
    path    => $::samba::params::smbConfFile,
    section => 'global',
    setting => 'log level',
    value   => "${sambaloglevel}${logadditional}",
  }

  # If specify, configure syslog
  if $logtosyslog {
    smb_setting { 'global/syslog':
      ensure  => present,
      path    => $::samba::params::smbConfFile,
      section => 'global',
      setting => 'syslog',
      value   => "${sambaloglevel}${logadditional}",
    }

    smb_setting { 'global/syslog only':
      ensure  => present,
      path    => $::samba::params::smbConfFile,
      section => 'global',
      setting => 'syslog only',
      value   => 'yes',
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
    }

    smb_setting { 'global/syslog':
      ensure  => absent,
      path    => $::samba::params::smbConfFile,
      section => 'global',
      setting => 'syslog',
    }
  }
}
