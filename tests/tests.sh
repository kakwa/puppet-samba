#!/bin/sh

cd `dirname $0`
puppet module install puppetlabs-stdlib --modulepath=`pwd`/../../

puppet apply --certname=ad.example.org examples/domain_controller.pp --modulepath=`pwd`/../../ --debug

ret=$?

[ $ret -eq 0 ] || echo "AD step failed"

# some clean up
apt-get purge -y samba-common
apt-get autoremove -y
rm -f /usr/local/bin/additional-samba-tool
rm -f /usr/local/bin/smb-create-home.sh

exit $ret
