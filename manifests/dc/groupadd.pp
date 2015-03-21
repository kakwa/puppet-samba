define samba::dc::groupadd{
  $groupName        = $::samba::dc::groups[$title]['name']
  $groupScope       = $::samba::dc::groups[$title]['scope']
  $groupType        = $::samba::dc::groups[$title]['type']
  $groupDescription = $::samba::dc::groups[$title]['description']

  # Check valid group type
  $groupTypeList = ['Security', 'Distribution']
  $groupTypeStr  = join($groupTypeList, ', ')
  unless member($groupTypeList, $groupType) {
      fail("type of group '${groupName}' must be in [$groupTypeStr]")
  }

  # Check valid group scope
  $groupScopeList = ['Domain', 'Global', 'Universal']
  $groupScopeStr  = join($groupScopeList, ', ')
  unless member($groupScopeList, $groupScope) {
      fail("scope of group '${groupName}' must be in [$groupScopeStr]")
  }

  exec{ "add Group $name":
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    # Check if group exists
    unless  => "${::samba::params::sambaCmd} group list --verbose | \
grep -qe '^${groupName}\\ *${groupType}\\ *${groupScope}$'",
    # create the group
    command => "${::samba::params::sambaCmd} group add '${groupName}' \
--group-scope='${groupScope}' --group-type='${groupType}' \
--description='${groupDescription}'",
    require => Service['SambaDC'],
  }
}
# vim: tabstop=8 expandtab shiftwidth=2 softtabstop=2
