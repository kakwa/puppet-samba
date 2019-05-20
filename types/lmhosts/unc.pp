# @summary
#   Universal Naming Convention: http://bit.ly/2ZDzmBd
#
type Samba::Lmhosts::UNC = Struct[
  {
    host             => Stdlib::Host,
    share            => Pattern[/\A[^\x00-\x1f\x22\x2a-\x2c\x2f\x3a-\x3f\x5b-\x5d\x7c]{1,80}\z/],
    path             => Pattern[/\A[^\x00-\x19\x22\x2a-\x2c\x2f\x3a-\x3f\x5b-\x5d\x7c]{1,255}\z/],
    Optional[file]   => Pattern[/\A[^\x00-\x1f\x22\x2a\x2f\x2a\x3c\x3e\x2f\x5c\x7c]{1,255}\z/],
    Optional[stream] => Pattern[/\A[\x00\x2f\x3a\x5c]*\z/],
    Optional[stype]  => Pattern[/\A[\x00\x2f\x3a\x5c]\z/],
  }
]
