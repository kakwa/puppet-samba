# Logon script resource

define samba::dc::script(
  $content,
){
  $scriptname       = $name
  $scriptcontent    = $content

  $scriptpath = "${::samba::dc::scriptdir}/${scriptname}"
  validate_absolute_path($scriptpath)

  file { $scriptpath:
    content => regsubst($scriptcontent, '(?<!\r)\n', "\r\n", 'EMG'),
    mode    => '0755',
    require => Exec['provisionAD'],
  }
}
# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
