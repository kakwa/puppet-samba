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

  $classlist = $samba::params::logclasslist
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


  if $sambaloglevel != undef {
    $syslog_loglevel = "syslog@${sambaloglevel}"
  } else {
    $syslog_loglevel = 'syslog'
  }

  # Configure Loglevel
  unless member($settingsignored, 'log level'){
    smb_setting { 'global/log level':
      ensure  => present,
      path    => $samba::params::smbconffile,
      section => 'global',
      setting => 'log level',
      value   => "${sambaloglevel}${logadditional}",
    }
  }

  # If specify, configure syslog
  if $logtosyslog {
    if versioncmp($facts['samba_version'], '4.3.0') <= 0 {
      unless member($settingsignored, 'syslog'){
        smb_setting { 'global/syslog':
          ensure  => present,
          path    => $samba::params::smbconffile,
          section => 'global',
          setting => 'syslog',
          value   => "${sambaloglevel}${logadditional}",
        }
      }

      unless member($settingsignored, 'syslog only'){
        smb_setting { 'global/syslog only':
          ensure  => present,
          path    => $samba::params::smbconffile,
          section => 'global',
          setting => 'syslog only',
          value   => 'yes',
        }
      }
    } else {
      unless member($settingsignored, 'logging'){
        smb_setting { 'global/logging':
          ensure  => present,
          path    => $samba::params::smbconffile,
          section => 'global',
          setting => 'logging',
          value   => $syslog_loglevel,
        }
      }
    }
  }
  # If not, keep login ing file, and disable syslog
  else {
    if versioncmp($facts['samba_version'], '4.3.0') <= 0 {
      unless member($settingsignored, 'syslog only'){
        smb_setting { 'global/syslog only':
          ensure  => present,
          path    => $samba::params::smbconffile,
          section => 'global',
          setting => 'syslog only',
          value   => 'no',
        }
      }

      unless member($settingsignored, 'syslog'){
        smb_setting { 'global/syslog':
          ensure  => absent,
          path    => $samba::params::smbconffile,
          section => 'global',
          setting => 'syslog',
        }
      }
    } else {
      unless member($settingsignored, 'logging'){
        smb_setting { 'global/logging':
          ensure  => absent,
          path    => $samba::params::smbconffile,
          section => 'global',
          setting => 'logging',
        }
      }
    }
  }
}
