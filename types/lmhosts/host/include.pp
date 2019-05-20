# @summary
#   One more more files or UNC paths.
#
type Samba::Lmhosts::Host::Include = Variant[
  Array[Samba::Lmhosts::Host::Filesource,2]
  Samba::Lmhosts::Host::Filesource,
]