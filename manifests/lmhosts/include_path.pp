# @summary Add an #INCLUDE path to the lmhosts file.
#
# If the order and path are unspecified, the title must
# consist of a filepath followed by a space and a valid
# order string.
#
# @example
#   samba::lmhosts::include_path { '/etc/lmhosts 1234':
#     include_path => '//pdc/share/lmhosts',
#   }
#
# @param [Samba::Lmhosts::Include_path::Path] include_path
#   Local path or UNC of the lmhosts fragment to include.
#
# @param [Samba::Lmhosts::Order] index
#   Used by stdlib::concat to assemble lmhosts fragments in the correct order.
#
# @param [Stdlib::Absolutepath] path
#   The file path of the lmhosts file being managed.
#
define samba::lmhosts::include_path (
  Samba::Lmhosts::Include_path::Path $include_path,
  Samba::Lmhosts::Order              $index = regsubst($title, /\A(.+)[ ]([0-9.]+)\z/, '\\2'),
  Stdlib::Absolutepath               $path  = regsubst($title, /\A(.+)[ ]([0-9.]+)\z/, '\\1'),
) {
  $order = $index ? {
    Integer => String($index, '%04d'),
    default => $index,
  }
  concat::fragment { "samba::lmhosts::include_path ${title}":
    content => "#INCLUDE ${include_path}\r\n",
    order   => $order,
    target  => $path,
  }
}
