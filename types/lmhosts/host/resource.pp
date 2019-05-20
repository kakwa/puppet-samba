# @summary
#   Struct of lmhosts::host attributes suitable for passing as the third parameter
#   to ensure_resource().
#
type Lmhosts::Host::Resource = Struct[
  {
    address            => Stdlib::IP::Address::V4::Nosubnet,
    Optional[ensure]   => Enum['absent','present'],
    Optional[domain]   => Samba::Lmhosts::Host::Name,
    Optional[host]     => Samba::Lmhosts::Host::Name,
    Optional[index]    => Integer[1],
    Optional[multiple] => Boolean,
    Optional[path]     => Stdlib::Absolutepath,
    Optional[preload]  => Boolean,
    Optional[service]  => Integer[0x00,0xff],
  }
]
