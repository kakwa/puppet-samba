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
  exec{ 'setPPolicy':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => Service['SambaDC'],
    unless  => "\
[ \"\$( ${::samba::params::sambacmd} domain passwordsettings show -d 1 \
|sed 's/^.*:\\ *\\([0-9]\\+\\|on\\|off\\).*$/\\1/gp;d' | md5sum )\" = \
\"\$(printf \
'${ppolicycomplexity}\\n${ppolicyplaintext}\\n${ppolicyhistorylength}\
\\n${ppolicyminpwdlength}\\n${ppolicyminpwdage}\\n${ppolicymaxpwdage}\\n' \
| md5sum )\" ]",

    command => "${::samba::params::sambacmd} domain passwordsettings set -d 1 \
--complexity='${ppolicycomplexity}' \
--store-plaintext='${ppolicyplaintext}' \
--history-length='${ppolicyhistorylength}' \
--min-pwd-length='${ppolicyminpwdlength}' \
--min-pwd-age='${ppolicyminpwdage}' \
--max-pwd-age='${ppolicymaxpwdage}'",
  }
}
