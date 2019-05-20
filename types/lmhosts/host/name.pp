# @summary
#   A Netbios hostname may be up to 15 characters long. Due to DNS restrictions,
#   it may not be composed entirely of numbers.  It may contain any character
#   except for the following:
#   * backslash (\)
#   * slash mark (/)
#   * colon (:)
#   * asterisk (*)
#   * question mark (?)
#   * quotation mark (")
#   * less than sign (<)
#   * greater than sign (>)
#   * vertical bar (|)
#   * period (.) -- Windows 2000 and later only.
#
type Samba::Lmhosts::Host::Name = Pattern[/\A[^\\\/:*?"<>|]{1,15}\z/]
