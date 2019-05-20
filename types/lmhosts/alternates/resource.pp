# @summary
#   Ordered List of alternate file or UNC locations where Lmhosts fragments may be found.
#
type Samba::Lmhosts::Alternates::Resource = Struct[
  {
    alternates      => Array[Samba::Lmhosts::Include_path::Path],
    Optional[index] => Samba::Lmhosts::Order,
    Optional[path]  => Stdlib::Absolutepath,
  }
]
