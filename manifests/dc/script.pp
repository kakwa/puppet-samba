define samba::dc::script(
  $content,
){
  $scriptName       = $name
  $scriptContent    = $content

  $scriptPath = "${::samba::dc::scriptDir}/${scriptName}"
  validate_absolute_path($scriptPath)

  file { $scriptPath:
    content => regsubst($scriptContent, '(?<!\r)\n', "\r\n", 'EMG'),
    mode    => '0755',
    require => Exec['provisionAD'],
  }
}
# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
