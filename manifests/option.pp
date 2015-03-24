define samba::option(
      $options,
      $section,
){
  $index = regsubst($title, '^.*:([0-9]+)$', '\1')
  $optionsSetting    = $options[$index]['setting']
  $optionsValue      = $options[$index]['value']

  smb_setting { "${section}/${optionsSetting}":
    ensure            => present,
    path              => $::samba::params::smbConfFile,
    section           => $section,
    setting           => $optionsSetting,
    value             => $optionsValue,
    key_val_separator => ' = ',
  }
}
