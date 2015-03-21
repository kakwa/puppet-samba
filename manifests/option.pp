define samba::option(
      $options,
      $section,
){
  $optionsSetting    = $options[$title]['setting']
  $optionsValue      = $options[$title]['value']

  ini_setting { "$section param: ${optionsSetting}":
    ensure  => present,
    path    => $::samba::params::smbConfFile,
    section => $section,
    setting => $optionsSetting,
    value   => $optionsValue,
    require => Exec['provisionAD'],
    notify  => Service['SambaDC'],
  }
}
