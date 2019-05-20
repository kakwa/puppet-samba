# @summary
#   An include contains either a local file path or a UNC path.
#
type Samba::Lmhosts::Include_path::Resource = Struct[
  {
    include_path    => Samba::Lmhosts::Include_path::Path,
    Optional[index] => Samba::Lmhosts::Order,
    Optional[path]  => Stdlib::Absolutepath,
  }
]
