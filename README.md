# puppet-samba

## WORK IN PROGRESS ##

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
    * [What samba affects](#what-samba-affects)
    * [Setup requirements](#setup-requirements)
4. [Usage](#usage)
5. [Limitations](#limitations)
6. [Development](#development)

## Overview

A module managing Samba 4 deployment, including Samba Domain Controler.

## Module Description

This module manage Samba 4 installation.

For now it only support Samba AD DC deployment (work in progress).

For now it only works under CentOS/RedHat.

## Setup

### Setup Requirements

Under RedHat/CentOS, this module requires the Sernet repos to be configured.
As of  march 2015, CentOS/RedHat doesn't support Samba 4 AD DC due to choice in kerberos implementations.

This module requires puppetlabs-stdlib and puppetlabs-inifile modules.

## Usage

### Samba 4 AD Domain Controler

```puppet
class { ::samba::dc:
  # Mandatory parameters
  domain                => 'ad',              # * AD domain name
  realm                 => 'ad.example.org',  # * Realm name (must match domain)
  dnsbackend            => 'internal',        # * DNS backend ('internal', 
                                              #   'bindFlat' or 'bindDLZ')
  adminpassword         => 'P455WordS',       # * Administrator password

  # Optionnal parameters
  dnsforwarder          => 8.8.8.8,           # * Dns forwarder IP (default: undef)
  ppolicycomplexity     => 'on',              # * Enable password policy (default: on)
  ppolicyplaintext      => 'off',             # * Store password in plain text 
                                              #   (default: off)
  ppolicyhistorylength  => 24,                # * Password history length (default: 24)
  ppolicyminpwdlength   => 7,                 # * Minimum password length (default: 7)
  ppolicyminpwdage      => 1,                 # * Minimum password age (default: 1)
  ppolicymaxpwdage      => 42,                # * Maximum password age (default: 42)
  targetdir             => '/var/lib/samba/', # * Deployment directory 
                                              #   (default: '/var/lib/samba/')
  domainlevel           => '2003',            # * Functionnality level ('2003',
                                              #   '2008' or '2008 R2') (default 2003)
  sambaloglevel         => 3,                 # * Log level (from 1 to 10) (default: 1)
  logtosyslog           => false,             # * Log not to file but to syslog 
                                              #   (default: false)
  sambaclassloglevel    => {                  # * Set log level by log classes
    'printdrivers' => 1,                      #   (default: undef)
    'idmap'        => 5,
    'winbind'      => 3,
  },

  globaloptions         => {                  # * Custom options in section [global] 
                                              #   Takes precedence.
                                              #   (default: {})
    'custom setting 1'   => 'custom value 1',
    'custom setting 2'   => 'custom value 2',
  },

  netlogonoptions       => [],                # * Custom options in section [netlogon]
  sysvoloptions         => [],                # * Custom options in section [sysvol]
  globalabsentoptions   => ['idmap_ldb:use'], # * Remove default settings put 
                                              #   by this class in [global] (default: [])
  sysvolabsentoptions   => [],                # * remove default settings put 
                                              #   by this class in [sysvol] (default: [])
  netlogonabsentoptions => [],                # * Remove default settings put 
                                              #   by this class in [netlogon] (default: [])
  groups                => [                  # * List of groups (default: [])
    { name        => 'group1',                # * group name
      description => 'Group 1',               # * group description
      scope       => 'Domain',                # * group scope 
                                              #   ('Domain', 'Global' or 'Universal')
      type        => 'Security',              # * group type 
                                              #   ('Security' or 'Distribution')
    },
    { name        => 'group2',
      description => 'Group 2',
      scope       => 'Global',
      type        => 'Distribution',
    },
  ],
  logonscripts          => [                  # * Logon scripts (default: [])
    { name          => 'login1.cmd',          # * Logon script name
      content       => 'echo login script 1 
ping -n 11 127.0.0.1 > nul
',                                            # * Logon script content
    },
    { name          => 'login2.cmd',
      content       => 'echo login script 2
ping -n 11 127.0.0.1 > nul
',
    },
  ],
}
```

### Samba Classic (shares)

```puppet
class { '::samba::classic':
  # Mandatory parameters
  domain                => 'DC',          # * Domain to authentify against
  realm                 => 'dc.kakwa.fr', # * Realm to authentify agains
  smbname               => 'SMB',         # * Share name
  adminpassword         => 'qwertyP455',  # * Domain Administrator 
                                          #   password (for joining)
  sambaloglevel         => 3,             # * Samba log level
  logtosyslog           => true,          # * Log to Syslog
  idrangemin            => 10000,         # * min uid for Domain users
  idrangemax            => 19999,         # * max uid for Domain users

  # Optionnal parameters
  sambaclassloglevel    => {        # * Set log level by log classes
    'printdrivers' => 1,            #   (default: undef)
    'idmap'        => 5,
    'winbind'      => 3,
  },
  globaloptions       => {},        # * Custom options in section [global] 
  globalabsentoptions => [],        # * Remove default settings put 
                                    #   by this class in [global]

}
```

### Samba Shares

```puppet
::samba::share { 'Test Share':
  # Mandatory parameters
  path            => '/srv/test/',
  # Optionnal parameters
  options         => {            # * Custom options in section [Test Share] 
      'browsable'     => 'Yes',
      'root preexec'  => 'mkdir -p \'/home/home_%U\'',
  },
  absentoptions   => ['path']     # * Remove default settings put by this resource
                                  #   default?: []
}
```

## Limitations

For now, this module only works on RedHat/CentOS, with Sernet packages.

## Development

Pull requests are welcomed ^^

## Release Notes

No Release yet.
