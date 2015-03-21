define samba::dc::scriptadd{ 
  $scriptName       = $::samba::dc::logonscripts[$title]['name'] 
  $scriptContent    = $::samba::dc::logonscripts[$title]['content'] 

  $scriptPath = "${::samba::dc::targetdir}/state/sysvol/${::samba::dc::realmDowncase}/scripts/${scriptName}" 
  validate_absolute_path($scriptPath) 

  file { "${scriptPath}": 
     content => "${scriptContent}", 
     mode    => "0755", 
     require => Exec['provisionAD'], 
  } 
} 
