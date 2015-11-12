# log resource 

define samba::log(
  $sambaloglevel,
  $logtosyslog,
  $settingsignored,
  $sambaclassloglevel = undef,
) {

  unless is_integer($sambaloglevel)
    and ($sambaloglevel + 0) >= 0
    and ($sambaloglevel + 0) <= 10{
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
  unless member($settingsignored, 'log level'){
    smb_setting { 'global/log level':
      ensure  => present,
      path    => $::samba::params::smbconffile,
      section => 'global',
      setting => 'log level',
      value   => "${sambaloglevel}${logadditional}",
    }
  }

  # If specify, configure syslog
  if $logtosyslog {
    unless member($settingsignored, 'syslog'){
      smb_setting { 'global/syslog':
        ensure  => present,
        path    => $::samba::params::smbconffile,
        section => 'global',
        setting => 'syslog',
        value   => "${sambaloglevel}${logadditional}",
      }
    }

    unless member($settingsignored, 'syslog only'){
      smb_setting { 'global/syslog only':
        ensure  => present,
        path    => $::samba::params::smbconffile,
        section => 'global',
        setting => 'syslog only',
        value   => 'yes',
      }
    }
  }
  # If not, keep login ing file, and disable syslog
  else {
    unless member($settingsignored, 'syslog only'){
      smb_setting { 'global/syslog only':
        ensure  => present,
        path    => $::samba::params::smbconffile,
        section => 'global',
        setting => 'syslog only',
        value   => 'no',
      }
    }

    unless member($settingsignored, 'syslog'){
      smb_setting { 'global/syslog':
        ensure  => absent,
        path    => $::samba::params::smbconffile,
        section => 'global',
        setting => 'syslog',
      }
    }
  }
}
