#!/bin/sh
puppet module install puppetlabs-stdlib --modulepath=`pwd`/../

puppet apply --certname=ad.example.org examples/domain_controller.pp --modulepath=`pwd`/../ --debug

ret=$?

apt-get purge -y samba-common
apt-get autoremove -y
rm -f /usr/local/bin/additional-samba-tool
rm -f /usr/local/bin/smb-create-home.sh

exit $ret
