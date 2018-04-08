# Logon script resource

define samba::dc::script(
  String $content,
){
  $scriptname       = $name
  $scriptcontent    = $content

  $scriptpath = "${samba::dc::scriptdir}/${scriptname}"
  assert_type(Stdlib::Absolutepath, $scriptpath)

  file { $scriptpath:
    content => regsubst($scriptcontent, '(?<!\r)\n', "\r\n", 'EMG'),
    mode    => '0755',
    require => Exec['provisionAD'],
  }
}
# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
