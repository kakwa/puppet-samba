# generic option resource

define samba::option(
      $options,
      $section,
      $settingsignored = [],
){
  $optionsSetting = regsubst($title, '^\[.*\](.*)$', '\1')
  $optionsValue   = $options[$optionsSetting]

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
