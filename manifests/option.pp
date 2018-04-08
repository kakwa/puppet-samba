# generic option resource

define samba::option(
      $options,
      $section,
      $settingsignored = [],
){
  $optionssetting = regsubst($title, '^\[.*\](.*)$', '\1')
  $optionsvalue   = $options[$optionssetting]

  unless member($settingsignored, $optionssetting){
    smb_setting { "${section}/${optionssetting}":
      ensure            => present,
      path              => $samba::params::smbconffile,
      section           => $section,
      setting           => $optionssetting,
      value             => $optionsvalue,
      key_val_separator => ' = ',
    }
  }
}
