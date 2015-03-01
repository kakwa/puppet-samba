class samba::params(
  $sernetRepo = true,
){
  unless is_bool($sernetRepo){
    fail('sernetRepo variable must be a boolean')
  }
  if $sernetRepo {
    case $::osfamily {
      'redhat': {
          $packageSambaDC   = 'sernet-samba-ad'
          $serviveSambaDC   = 'sernet-samba-ad'
	  $sambaCmd	    = '/usr/bin/samba-tool'
          $sambaClientCmd   = '/usr/bin/smbclient'  
	  $sambaOptsFile    = '/etc/default/sernet-samba'
	  $sambaOptsTmpl    = "${module_name}/sernet-samba.erb"
      }
      default: {
          fail('unsupported os')
      }
    }
  }else{
    case $::osfamily {
      'redhat': {
          fail('CentOS/RedHat don\'t support Samba 4 AD')
      }
      default: {
          fail('unsupported os')
      }
    }
  }
}
