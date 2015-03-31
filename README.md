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

This module manage Samba 4 installation. It's mainly meant to deploy Samba 4 as a domain controler
and it's associated shares, but as it's possible to remove/modify/add any samba parameters this
module can be used for any samba setup.

For now it only works under CentOS/RedHat.

## Setup

### Setup Requirements

Under RedHat/CentOS, this module requires the Sernet repos to be configured.
As of  march 2015, CentOS/RedHat doesn't support Samba 4 AD DC due to choice in kerberos implementations.

This module requires puppetlabs-stdlib module.

## Usage

### Samba 4 AD Domain Controler

```puppet
class { ::samba::dc:
  # Mandatory parameters
  domain                => 'ad',              # * AD domain name
  realm                 => 'ad.example.org',  # * Realm name (must match domain)
  dnsbackend            => 'internal',        # * DNS backend ('internal', 
                                              #   'bindFlat' or 'bindDLZ')

  # Optionnal parameters
  adminpassword         => 'P455WordS',       # * Administrator password 
                                              #   (default: undef)
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
  netlogonoptions       => {},                # * Custom options in section [netlogon]
  sysvoloptions         => {},                # * Custom options in section [sysvol]
  globalabsentoptions   => ['idmap_ldb:use'], # * Remove default settings put 
                                              #   by this class in [global] 
                                              #   (default: [])
  sysvolabsentoptions   => [],                # * remove default settings put 
                                              #   by this class in [sysvol] 
                                              #   (default: [])
  netlogonabsentoptions => [],                # * Remove default settings put 
                                              #   by this class in [netlogon] 
                                              #   (default: [])
  logonscripts          => [                  # * List of logon scripts (default: [])
    { name          => 'login1.cmd',          # * Logon script name
      content       => 'echo login script 1 
ping -n 11 127.0.0.1 > nul
',                                            # * Logon script content
    },
  ],
}
```

Adding users:

```puppet
smb_user { 'test user':                       # * user name
  ensure     => present,                      # * absent | present
  password   => 'QwertyP455aaa',              # * user password
  groups     => ['domain users',              # * list of groups
     'administrators'],
  attributes => {                             # * hash of attributes
     uidNumber   => '15222',                  #   use list for multivalued attributes
     gidNumber   => '10001',
     msSFU30NisDomain => 'dc',
     mail => ['test@toto.fr'],
  },
}
```

Adding groups:

```puppet
smb_group { 'mygroup':
  ensure     => present,                      # * group name
  scope      => 'Domain',                     # * group scope
  type       => 'Security',                   # * group type
  attributes => {                             # * attributes
    gidNumber        => '15220',              #   use list for multivalued attributes
    msSFU30NisDomain => 'dc',
  },
  groups     => ['domain users',              # * list of groups
    'administrators'], 
}
```

### Samba Classic (shares)

```puppet
class { '::samba::classic':
  # Mandatory parameters
  domain                => 'DC',          # * Domain to authentify against
  realm                 => 'dc.kakwa.fr', # * Realm to authentify against
  smbname               => 'SMB',         # * Share name
  sambaloglevel         => 3,             # * Samba log level
  logtosyslog           => true,          # * Log to Syslog
  idrangemin            => 10000,         # * Min uid for Domain users
  idrangemax            => 19999,         # * Max uid for Domain users

  # Optionnal parameters
  krbconf               => true,          # * Deploy krb5.conf file (default: true)
  nsswitch              => true,          # * Add winbind to nsswitch,
                                          #   (default: true)
  adminpassword         => 'P455WordS',   # * Domain Administrator 
                                          #   password (for joining)
                                          #   (default: undef, no join)
  sambaclassloglevel    => {              # * Set log level by log classes
    'printdrivers' => 1,                  #   (default: undef)
    'idmap'        => 5,
    'winbind'      => 3,
  },
  globaloptions       => {},              # * Custom options in section [global] 
  globalabsentoptions => [],              # * Remove default settings put 
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
  absentoptions   => ['path'],    # * Remove default settings put by this resource
                                  #   default?: []
}
```

## Limitations

For now, this module only works on RedHat/CentOS, with Sernet packages.

To access Sernet Repositories, you must register on [Sernet Portal](https://portal.enterprisesamba.com/users/sign_up).
Once it's done, you should have access to your *ACCESSKEY*. Use it and your USERNAME to configure the repo:

sernet-samba-4.1.repo:
```ini
[sernet-samba-4.1]
name=SerNet Samba 4.1 Packages (centos-7)
type=rpm-md
baseurl=https://USERNAME:ACCESSKEY@download.sernet.de/packages/samba/4.1/centos/7/
gpgcheck=1
gpgkey=https://USERNAME:ACCESSKEY@download.sernet.de/packages/samba/4.1/centos/7/repodata/repomd.xml.key
enabled=1
```

sernet-samba-4.1.list:
```yml
deb https://USERNAME:ACCESSKEY@download.sernet.de/packages/samba/4.1/debian wheezy main
deb-src https://USERNAME:ACCESSKEY@download.sernet.de/packages/samba/4.1/debian wheezy main
```

This module will not configure the repo, you have to do it otherwise.

## Development

Pull requests are welcomed ^^.

## Release Notes

No Release yet.
