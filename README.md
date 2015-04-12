# puppet-samba

## WORK IN PROGRESS ##

#### Table of Contents

1. [Module Description](#module-description)
2. [Setup](#setup)
    * [What samba affects](#what-samba-affects)
    * [Setup requirements](#setup-requirements)
3. [Usage](#usage)
    * [Packages](#packages)
    * [Samba Domain Controller](#samba-4-ad-domain-controler)
          * [Domain Controller](#domain-controller)
          * [Password Policy](#password-policy)
          * [Logon Script](#logon-scripts)
          * [User](#users)
          * [Group](#groups)
    * [Samba Classic](#samba-classic)
    * [Idmap](#idmap)
          * [nss, tdb or rid](#idmap-nss-tdb-or-rid)
          * [ad](#idmap-ad)
          * [autorid](#idmap-autorid)
          * [hash](#idmap-hash)
          * [ldap](#idmap-ldap)
          * [tdb2](#idmap-tdb2)
    * [Shares](#samba-shares)
4. [Limitations](#limitations)
5. [Development](#development)
6. [Release Notes](#release-notes)

## Module Description

This module manage Samba installation, including samba as an **Active Directory Domain Controler**.

It easily lets you add/modify/remove any parameters of smb.conf, letting you free to customize the installation
to your specific needs. 

## Setup

### What samba affects

This module will install the samba packages and setup smb.conf.

In 'classic':

* By default, it will enable winbind in nsswitch (through augeas, not modifying anything more than necessary).
* By default, it will join the share the Domain Controler.
* It will configure and enable the winbind service
* It will deploy 'smb-create-home.sh', a small helper script to create user's home

In 'dc':

* It will deploy additionnal-samba-tool, a python script completing samba-tool
This script handles users/groups and their attributes (list, add or remove attributes)

### Setup Requirements

This module requires puppetlabs-stdlib module.

## Usage

### Packages

This module permits to choose between native distribtion packages or Sernet (samba developpers) packages:

```puppet
class { 'samba::params':
  sernetRepo => true, # enable sernet packages (default: false)
}
```

If this class is undeclared, the default behavior is to use native distribution packages.

As of march 2015, CentOS/RedHat doesn't support Samba 4 AD DC due to choice in kerberos implementations.
Use the Sernet Packages.

If the Sernet packages are used, please configure Sernet/Custom repositories containing these packages.

### Samba 4 AD Domain Controler

#### Domain Controller

To provision the domain controller use the *samba::dc* class:

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
  dnsforwarder          => '8.8.8.8',         # * Dns forwarder IP (default: undef)
  ip                    => '192.168.1.1'      # * DC listening IP (default undef)
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
  sysvolabsentoptions   => [],                # * remove default settings in [sysvol]
  netlogonabsentoptions => [],                # * Remove default settings in [netlogon]
}
```

#### Password Policy

Configuring password Policy:

```puppet
class { ::samba::dc::ppolicy:
  ppolicycomplexity     => 'on',              # * Enable password policy (default: on)
  ppolicyplaintext      => 'off',             # * Store password in plain text
                                              #   (default: off)
  ppolicyhistorylength  => 24,                # * Password history length (default: 24)
  ppolicyminpwdlength   => 7,                 # * Minimum password length (default: 7)
  ppolicyminpwdage      => 1,                 # * Minimum password age (default: 1)
  ppolicymaxpwdage      => 42,                # * Maximum password age (default: 42)
}
```

#### Logon Scripts

Adding logon scripts:

```puppet
::samba::dc::script { 'login1.cmd':           # * name of the script
  content => 'echo login script 1             # * content of the script
ping -n 11 127.0.0.1 > nul                    #   will automaticaly be converted
',                                            #   to CRLF End of Line.
}
```

#### Users

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

#### Groups

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

### Samba Classic

```puppet
class { '::samba::classic':
  # Mandatory parameters
  domain                => 'DC',          # * Domain to authentify against
  realm                 => 'dc.kakwa.fr', # * Realm to authentify against
  smbname               => 'SMB',         # * Share name
  sambaloglevel         => 3,             # * Samba log level
  logtosyslog           => true,          # * Log to Syslog

  # Optionnal parameters
  security              => 'ADS',         # * security mode.
                                          #   in ['ADS', 'AUTO', 'USER', 'DOMAIN']
                                          #   default: 'ADS'
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
}
```

### Idmap

#### Idmap nss, tdb or rid

* [Idmap nss](https://www.samba.org/samba/docs/man/manpages/idmap_nss.8.html)
* [Idmap rid](https://www.samba.org/samba/docs/man/manpages/idmap_rid.8.html)
* [Idmap tdb](https://www.samba.org/samba/docs/man/manpages/idmap_tdb.8.html)

```puppet
::samba::idmap { 'Domain *':
  domain      => '*',           # * name of the Domain or '*'
  idrangemin  => 10000,         # * Min uid for Domain users
  idrangemax  => 19999,         # * Max uid for Domain users
  backend     => 'tdb',         # * idmap backend
                                #   in [nss, tdb or rid]
}
```

#### Idmap ad

* [Idmap ad](https://www.samba.org/samba/docs/man/manpages/idmap_ad.8.html)

```puppet
::samba::idmap { 'Domain DC':
  domain      => 'DC',          # * name of the Domain or '*'
  idrangemin  => 10000,         # * Min uid for Domain users
  idrangemax  => 19999,         # * Max uid for Domain users
  backend     => 'ad',          # * idmap backend
  schema_mode => 'rfc2307',     # * Schema mode
                                #   in [rfc2307, sfu, sfu20]
}
```

#### Idmap autorid

* [Idmap autorid](https://www.samba.org/samba/docs/man/manpages/idmap_autorid.8.html)

```puppet
::samba::idmap { 'Domain DC':
  domain         => 'DC',          # * name of the Domain or '*'
  idrangemin     => 10000,         # * Min uid for Domain users
  idrangemax     => 19999,         # * Max uid for Domain users
  backend        => 'autorid',     # * idmap backend
  # Optionnal parameters
  rangesize      => 100000,        # * number of uid per domain
                                   #   default: 100000
  read_only      => 'yes',         # * Read only mappint
                                   #   Default no
  ignore_builtin => 'yes',         # * Ignore any mapping requests
                                   #   for the BUILTIN domain
}
```

#### Idmap hash

* [Idmap hash](https://www.samba.org/samba/docs/man/manpages/idmap_hash.8.html)

```puppet
::samba::idmap { 'Domain DC':
  domain     => 'DC',                     # * name of the Domain or '*'
  idrangemin => 10000,                    # * Min uid for Domain users
  idrangemax => 19999,                    # * Max uid for Domain users
  backend    => 'hash',                   # * idmap backend
  name_map   => '/etc/samba/name_map.cfg' # * mapping file
}
```

#### Idmap ldap

* [Idmap ldap](https://www.samba.org/samba/docs/man/manpages/idmap_ldap.8.html)

```puppet
::samba::idmap { 'Domain DC':
  domain       => 'DC',                         # * name of the Domain or '*'
  idrangemin   => 10000,                        # * Min uid for Domain users
  idrangemax   => 19999,                        # * Max uid for Domain users
  backend      => 'ldap',                       # * idmap backend
  ldap_base_dn => 'ou=users,dc=example,dc=com', # * users mapping ou
  ldap_user_dn => 'cn=smb,dc=example,dc=com',   # * bind account
  ldap_passwd  => 'password',                   # * bind password
  ldap_url     => 'ldap://ldap.example.com',    # * ldap url
}
```

#### Idmap tdb2

* [Idmap tdb2](https://www.samba.org/samba/docs/man/manpages/idmap_tdb2.8.html)

```puppet
::samba::idmap { 'Domain DC':
  domain     => 'DC',                     # * name of the Domain or '*'
  idrangemin => 10000,                    # * Min uid for Domain users
  idrangemax => 19999,                    # * Max uid for Domain users
  backend    => 'tdb2',                   # * idmap backend
  script     => '/etc/samba/map.sh',      # * mapping sid/uid script
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
