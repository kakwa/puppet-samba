define samba::option(
      $options,
      $section,
      $settingsignored = [],
){
  $index = regsubst($title, '^\[.*\](.*)$', '\1')
  $optionsSetting    = $index
  $optionsValue      = $options[$index]
  
  unless member($settingsignored, $optionsSetting){
    smb_setting { "${section}/${optionsSetting}":
      ensure            => present,
      path              => $::samba::params::smbConfFile,
      section           => $section,
      setting           => $optionsSetting,
      value             => $optionsValue,
      key_val_separator => ' = ',
    }
  }
}
