# Ppolicy class

class samba::dc::ppolicy (
  $ppolicycomplexity     = 'on',
  $ppolicyplaintext      = 'off',
  $ppolicyhistorylength  = 24,
  $ppolicyminpwdlength   = 7,
  $ppolicyminpwdage      = 1,
  $ppolicymaxpwdage      = 42,
) inherits ::samba::params{
  $checkpp = ['on', 'off', 'default']
  $checkppstr = join($checkpp, ', ')

  unless member($checkpp, $ppolicycomplexity){
    fail("ppolicycomplexity must be in [${checkppstr}]")
  }

  unless member($checkpp, $ppolicyplaintext){
    fail("ppolicyplaintext must be in [${checkppstr}]")
  }

  unless is_integer($ppolicyhistorylength){
    fail('ppolicyhistorylength must be an integer')
  }

  unless is_integer($ppolicyminpwdlength){
    fail('ppolicyminpwdlength must be an integer')
  }

  unless is_integer($ppolicyminpwdage){
    fail('ppolicyminpwdage must be an integer')
  }

  unless is_integer($ppolicymaxpwdage){
    fail('ppolicymaxpwdage must be an integer')
  }

  # Configure Password Policy
  samba::dc::ppolicy_param{'--complexity':
    option      => '--complexity',
    show_string => 'Password complexity:',
    value       => $ppolicycomplexity,
  }

  samba::dc::ppolicy_param{'--store-plaintext':
    option      => '--store-plaintext',
    show_string => 'Store plaintext passwords:',
    value       => $ppolicyplaintext,
  }

  samba::dc::ppolicy_param{'--history-length':
    option      => '--history-length',
    show_string => 'Password history length:',
    value       => $ppolicyhistorylength,
  }

  samba::dc::ppolicy_param{'--min-pwd-length':
    option      => '--min-pwd-length',
    show_string => 'Minimum password length:',
    value       => $ppolicyminpwdlength,
  }

  samba::dc::ppolicy_param{'--min-pwd-age':
    option      => '--min-pwd-age',
    show_string => 'Minimum password age (days):',
    value       => $ppolicyminpwdage,
  }

  samba::dc::ppolicy_param{'--max-pwd-age':
    option      => '--max-pwd-age',
    show_string => 'Maximum password age (days):',
    value       => $ppolicymaxpwdage,
  }
}
