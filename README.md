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

### Samba 4 AD DC

```puppet
class { ::samba::dc:
  domain		=> 'ad',		# AD domain name
  realm			=> 'ad.example.org',	# realm name (must match domain)
  dnsbackend		=> 'internal',		# DNS backend ('internal', 'bindFlat' or 'bindDLZ')
  dnsforwarder		=> 8.8.8.8,		# Dns forwarder IP
  adminpassword		=> P455WordS,		# Administrator password
  ppolicycomplexity	=> 'on',		# Enable password policy
  ppolicyplaintext	=> 'off',		# Store password in plain text
  ppolicyhistorylength	=> 24,			# Password history length
  ppolicyminpwdlength	=> 7,			# Minimum password length
  ppolicyminpwdage	=> 1,			# Minimum password age
  ppolicymaxpwdage	=> 42,			# Maximum password age
  targetdir		=> '/var/lib/samba/',	# Deployment directory
  domainlevel		=> '2003',		# Functionnality level ('2003', '2008' or '2008 R2')
}
```

## Limitations

For now, this module only works on RedHat/CentOS

## Development

Pull requests are welcomed ^^

## Release Notes

No Release yet.
