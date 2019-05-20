# @summary Add a host entry to the lmhosts file.
#
# A host entry consists of an IPv4 address, an smb netbios name, and some
# optional flags.
#
# @example
#   samba::lmhosts::host { '/etc/lmhosts localhost':
#     address: '127.0.0.1',
#     preload: true,
#   }
#
# @param [Stdlib::IP::Address::V4::Nosubnet] address
#   The IPv4 address of this host entry.
#
# @param [Enum['absent','present']] ensure
#   Whether to remove ('absent') or add ('present') this host entry.
#
# @param [Optional[Samba::Lmhosts::Host::Name]] domain
#   The Samba domain to which this host will be added, if diferent from the
#   default domain.
#
# @param [Samba::Lmhosts::Host::Name] host
#   The netbios name of this computer or service.
#
# @param [Optional[Samba::Lmhosts::Order]] index
#   Used by the concat module to assemble the lmhosts file from parts.
#
# @param [Boolean] multiple
#   If true, this is one of up to 25 entries for the same host.
#
# @param [Stdlib::Absolutepath] path
#   The location of the lmhosts file.
#
# @param [Boolean] preload
#   If true (default), this entry should be preloaded into cache.
#
# @param [Optional[Integer[0x00,0xff]]] service
#   An optional integer service code.  See $samba::lmhosts::host::service
#
define samba::lmhosts::host (
  Stdlib::IP::Address::V4::Nosubnet        $address,
  Enum['absent','present']                 $ensure   = 'present',
  Optional[Samba::Lmhosts::Host::Name]     $domain   = undef,
  Samba::Lmhosts::Host::Name               $host     = regsubst($title, /\A(.+)[ ]([^\\\/:*?"<>|]{1,15})\z/, '\\2'),
  Optional[Samba::Lmhosts::Order]          $index    = undef,
  Boolean                                  $multiple = false,
  Stdlib::Absolutepath                     $path     = regsubst($title, /\A(.+)[ ]([^\\\/:*?"<>|]{1,15})\z/, '\\1'),
  Boolean                                  $preload  = true,
  Optional[Integer[0x00,0xff]]             $service  = undef,
) {
  $_address = sprintf('%-15s', $address)
  $_domain = $domain ? {
    undef   => '',
    default => " #DOM:${domain}"
  }
  $_host = $service ? {
    undef   => sprintf('%-22s', $host),
    default => sprintf('"%-15s\\0x%2x"', $host, $service),
  }
  $_multiple = $multiple? {
    false   => '',
    default => ' #MH',
  }
  $_preload = $preload ? {
    false   => '',
    default => ' #PRE',
  }
  $_content = strip("${_address} ${_host}${_multiple}${_preload}")
  concat::fragment { "samba::lmhosts::host ${title}":
    content => "${_content}\r\n",
    order   => $index,
    target  => $path,
  }
}
