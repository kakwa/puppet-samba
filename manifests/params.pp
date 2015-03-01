class samba::params {
  case $::osfamily {
    'RedHat': {
        $packages = ['samba-dc']
    }
    default: {
        fail('Unsupported OS')
    }
  }
}
