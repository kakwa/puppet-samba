# @summary
#   A local or remote file path.
#
type Samba::Lmhosts::Host::Filesource = Variant[
  Samba::Lmhosts::UNC,
  Stdlib::Absolutepath,
]