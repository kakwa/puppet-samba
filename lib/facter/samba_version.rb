#!/usr/bin/ruby
require 'facter'

package = 'samba'


distid = Facter.value(:operatingsystem)

case distid
    when /RedHatEnterprise|CentOS|Fedora|RHEL/
        if  FileTest.exist?("/usr/bin/yum")
            version = Facter::Util::Resolution.exec('/usr/bin/yum info samba | sed \'s/Version *: \([0-9\.]\+\)/\1/gp;d\' | head -n 1')
        end
    when /Ubuntu|Debian/
        if  FileTest.exist?("/usr/bin/apt-cache")
            version = Facter::Util::Resolution.exec('apt-cache show samba | sed \'s/Version:.*:\([0-9\.]\+\).*/\1/gp;d\' | head -n 1')
        end
    when 'Archlinux'
      version = Facter::Util::Resolution.exec('pacman -Si samba | awk "/Version/ {print $3}" | cut -d"-" -f1')
    else
        version = "0.0.0"
end

#print distid
#print version

Facter.add("samba_version") do
    setcode do
        version
    end
end
