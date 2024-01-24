# Logon script resource

define samba::dc::ppolicy_param(
  $option,
  $show_string,
  String $value,
){

  if $option !~ /^--.*$/ {
    fail("option must start with '--' and be \
a valid 'samba-tool domain passwordsettings' option",
    )
  }

  if $show_string !~ /^.*:$/ {
    fail("show_string must end with ':' \
and be the string in 'samba-tool domain passwordsettings show' \
corresponding to option",
    )
  }

  exec{"cmd_ppolicy_param ${option}":
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => Service['SambaDC'],
    unless  => "[ \
\"\$( ${samba::params::sambacmd} domain passwordsettings show -d 1 | \
sed 's/${show_string} *//p;d' )\" = \
'${value}' ]",
    command => "${samba::params::sambacmd} domain passwordsettings set -d 1 \
${option}='${value}'",
  }
}
# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
