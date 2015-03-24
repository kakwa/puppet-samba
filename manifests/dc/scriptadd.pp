define samba::dc::scriptadd{
  $scriptName       = $::samba::dc::logonscripts[$title]['name']
  $scriptContent    = $::samba::dc::logonscripts[$title]['content']

  $scriptPath = "${::samba::dc::scriptDir}/${scriptName}"
  validate_absolute_path($scriptPath)

  file { $scriptPath:
    content => $scriptContent,
    mode    => '0755',
    require => Exec['provisionAD'],
  }
}
# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
