define samba::option(
      $options,
      $section,
){
  $optionsSetting    = $options[$title]['setting']
  $optionsValue      = $options[$title]['value']

  smb_setting { "${section}/${optionsSetting}":
    ensure            => present,
    path              => $::samba::params::smbConfFile,
    section           => $section,
    setting           => $optionsSetting,
    value             => $optionsValue,
    key_val_separator => ' = ',
  }
}
