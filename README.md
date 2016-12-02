# puppet-samba
[![Build Status](https://travis-ci.org/kakwa/puppet-samba.svg)](https://travis-ci.org/kakwa/puppet-samba)
[![Downloads](https://img.shields.io/puppetforge/dt/kakwa/samba.svg)](https://forge.puppetlabs.com/kakwa/samba)
[![Score](https://img.shields.io/puppetforge/f/kakwa/samba.svg)](https://forge.puppetlabs.com/kakwa/samba/scores)
[![Version](https://img.shields.io/puppetforge/v/kakwa/samba.svg)](https://forge.puppetlabs.com/kakwa/samba)

#### Table of Contents

1. [Module Description](#module-description)
2. [Setup](#setup)
    * [What samba affects](#what-samba-affects)
    * [Setup requirements](#setup-requirements)
3. [Usage](#usage)
    * [Examples](#examples)
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
    * [Samba Shares](#samba-shares)
          * [Shares](#shares)
          * [Directories](#directories)
4. [Limitations](#limitations)
5. [Development](#development)
6. [Release Notes](#release-notes)

## Module Description

This module manages Samba installation, including samba as an **Active Directory Domain Controler**.

Any parameter in smb.conf can be added/modified/removed, keeping you free to customize the installation
to your specific needs.

This module is licensed MIT.

The script additional-samba-tool is licensed GPLv3 (depends on python-samba which is GPLv3).

## Setup

### What samba affects

This module will install the samba packages and setup smb.conf.

In 'classic':

* By default, it will enable winbind in nsswitch (through augeas, not modifying anything more than necessary).
* By default, it will join the Domain Controller.
* It will configure and enable the winbind service
* It will deploy 'smb-create-home.sh', a small helper script to create user's home automatically

In 'dc':

* It will deploy additional-samba-tool, a python script completing samba-tool
This script handles users/groups and their attributes (list, add or remove attributes)

### Setup Requirements

This module requires puppetlabs-stdlib module.

## Usage

### Examples

Look at the [examples](https://github.com/kakwa/puppet-samba/tree/master/examples) directory.

### Packages

This module permits to choose between native distribution packages or Sernet (Samba developers) packages:

```puppet
class { 'samba::params':
  sernetpkgs => true, # enable sernet packages (default: false)
}
```

If this class is undeclared, the default behavior is to use native distribution packages. (see [Limitations](#limitations) for CentOS/RedHat)

If the Sernet packages are used, please configure a repository containing these packages.

### Samba 4 AD Domain Controller

#### Domain Controller

* [Domain Controller](https://wiki.samba.org/index.php/Samba_AD_DC_HOWTO)

To provision the domain controller use the *samba::dc* class:

```puppet
class { ::samba::dc:
  # Mandatory parameters
  domain                => 'ad',              # * AD domain name
  realm                 => 'ad.example.org',  # * Realm name (must match domain)

  # Optionnal parameters
  dnsbackend            => 'internal',        # * DNS backend ('internal',
                                              #   'bindFlat' or 'bindDLZ')
                                              #   default: internal
  adminpassword         => 'P455WordS',       # * Administrator password
                                              #   (default: undef)
  dnsforwarder          => '8.8.8.8',         # * Dns forwarder IP (default: undef)
  ip                    => '192.168.1.1'      # * DC listening IP (default undef)
  targetdir             => '/var/lib/samba/', # * Deployment directory
                                              #   (default: '/var/lib/samba/')
  domainlevel           => '2003',            # * Functionality level ('2003',
                                              #   '2008' or '2008 R2') (default 2003).
                                              #   Can be upgraded, but not downgraded
  domainprovargs        => '',                # * Additionnal arguments for domain
                                              #   provision (ex: --domain-sid)
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

If this class is not specified, default from samba-tool provisioning will be kept.

Password Policy parameters can be set individually:

```puppet
samba::dc::ppolicy_param{'account-lockout-duration':
  option      => '--account-lockout-duration',         # option name in samba-tool
  show_string => 'Account lockout duration (mins):',   # string name in show
  value       => '45',                                 # value
}
```

Use the following commands to list available options for your samba version

```bash
# List available options:
$ samba-tool domain passwordsettings --help

# List available string_show:
$ samba-tool domain passwordsettings show
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

* [Domain Member](https://wiki.samba.org/index.php/Setup_a_Samba_AD_Member_Server)

```puppet
class { '::samba::classic':
  # Mandatory parameters
  domain                => 'DC',             # * Domain to authentify against
  realm                 => 'dc.kakwa.fr',    # * Realm to authentify against
  smbname               => 'SMB',            # * Share name
  sambaloglevel         => 3,                # * Samba log level
  logtosyslog           => true,             # * Log to Syslog

  # Optionnal parameters
  strictrealm           => true,             # * Check for Strict Realm (default: true)
  security              => 'ADS',            # * security mode.
                                             # in ['ADS', 'AUTO', 'USER', 'DOMAIN']
                                             # default: 'ADS'
  manage_winbind        => true              # * Manage the winbind service (default: true)
  krbconf               => true,             # * Deploy krb5.conf file (default: true)
  nsswitch              => true,             # * Add winbind to nsswitch,
                                             # (default: true)
  join_domain           => true,             # * Flag to enable domain join (default: true)
  adminuser             => 'custadmin'       # * Domain Administrator login
                                             # (default: 'administrator')
  adminpassword         => 'P455WordS',      # * Domain Administrator
                                             # password (for joining)
                                             # (default: undef, no join)
  joinou                => 'Computer/Samba', # * OU to Join
  sambaclassloglevel    => {                 # * Set log level by log classes
    'printdrivers' => 1,                     # (default: undef)
    'idmap'        => 5,
    'winbind'      => 3,
  },
  globaloptions       => {},                 # * Custom options in section [global]
  globalabsentoptions => [],                 # * Remove default settings put
}
```

### Idmap

Idmap is to map user ids to unix uid/uid numbers, it supports several back-ends which can be configured with the following resources.

Note that configuring a '\*' domain seems necessary for Idmap to properly work. 

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

#### Shares

```puppet
::samba::share { 'Test Share':
  # Mandatory parameters
  path            => '/srv/test/',
  
  # Optionnal parameters
  manage_directory  => true,        # * let the resource handle the shared 
                                    #   directory creation (default: true)
  owner             => 'root',      # * owner of the share directory
                                    #   (default: root)
  group             => 'root',      # * group of the share directory 
                                    #   (default: root)
  mode              => '0775',      # * mode of the share directory
                                    #   (default: 0777)
  acl               => [],          # * list of posix acls (default: undef)
  options           => {            # * Custom options in section [Test Share]
      'browsable'       => 'Yes',
      'root preexec'    => 'mkdir -p \'/home/home_%U\'',
  },
  absentoptions     => ['path'],    # * Remove default settings put by this resource
                                    #   default?: []
}
```

#### Directories

If you want to create subdirectory in a share with specific permissions/acls:

```puppet
::samba::dir { 'Sub Dir':
  # Mandatory parameters
  path              => '/srv/test/sub',

  # Optionnal parameters
  owner             => 'root',      # * owner of the directory
                                    #   (default: root)
  group             => 'root',      # * group of the directory 
                                    #   (default: root)
  mode              => '0775',      # * mode of the directory
                                    #   (default: 770)
  acl               => [],          # * list of posix acls (default: undef)
}
```

## Limitations

class **samba::dc** (deploy Samba as a Domain Controller) needs Samba in version 4.0.0 or above.

This version is available in Debian Jessie and above, or in Wheezy using Debian backports.

As of march 2015, CentOS/RedHat doesn't support Samba 4 AD DC due to choices in kerberos implementations.
If you plan to deploy Samba as a DC on CentOS/RedHat use the Sernet Packages.

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

This module will not configure the repository, you have to do it otherwise.

## Development

Any form of contribution (bug reports, feature requests...) is welcomed. Pull requests will be merged after review.

If you have questions regarding how to use this module, don't hesitate to fill a bug. 

* [GitHub Bug Tracker](https://github.com/kakwa/puppet-samba/issues)
* [GitHub Pull requests](https://github.com/kakwa/puppet-samba/pulls)

Contribution must not raise errors from puppet-lint.

## Release Notes

0.7.2:

 * add switch join_domain to enable/disable Domain Join in classic class (Thanks to Mattias Giese)
 * add switch manage_winbind to enable/disable winbind service in classic class (Thanks to Mattias Giese)

0.7.1:

 * fix templates (thanks to Michael Sweetser)

0.7.0:

 * add parameter to pass additionnal parameters for domain provisioning 

0.6.2:

 * fix daemon name on Debian versions >=8 

0.6.1:
 * fix documentation

0.6.0:
 * add support for Ubuntu
 * fix for puppet 4

0.5.0:
 * add optional parameter joinou in class classic to specify the OU in AD where the samba server must be declared
 * add optional parameter strictrealm to enable/disable strict realm check

0.4.0:
 * add manage_directory parameter to samba::share in order to
 make directory creation optional (useful for print server)

0.3.1:
 * fix namespace collision between puppetlabs-inifile and smb_file resource
 * adding examples

0.3.0:
 * remove useless --workgroup option in DC provisioning
 * add type ppolicy_param to set individual ppolicy parameters
 * fix ppolicy class to be more robust to version changes

0.2.0:
 * adding parameter adminuser for class **samba::classic**
   default value (administrator) maintains the previous behaviour

0.1.2:

 * Better summary in metadata.json

0.1.1:

 * Better tags in metadata.json
 * Better documentation

0.1.0:

 * first release

## External licenses

This module includes portions of code derived from:

* [puppetlabs/inifile](https://forge.puppetlabs.com/puppetlabs/inifile) licensed under APL
* [python-samba](https://www.samba.org/) licensed under GPLv3
* [puppet-acl](https://github.com/dobbymoodge/puppet-acl) licensed under APL
