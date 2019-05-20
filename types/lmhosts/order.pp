# @summary
#   Used by concat to assemble parts of the lmhosts file in the correct order.
#
type Samba::Lmhosts::Order = Variant[
  Enum['catalog'],
  Integer[0,9999],
  Pattern[/\A[0-9]{4}\z/],
  Pattern[/\A[0-9]{4}[.][0-9]{4}\z/],
]
