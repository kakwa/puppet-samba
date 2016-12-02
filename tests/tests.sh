#!/bin/sh

cleanup(){
    # some clean up
    apt-get purge -y samba-common
    apt-get autoremove -y
    rm -f /usr/local/bin/additional-samba-tool
    rm -f /usr/local/bin/smb-create-home.sh
}

run(){
    pp=$1
    message=$2
    puppet apply --certname=ad.example.org $pp --modulepath=`pwd`/../ --debug
    tmp=$?
    [ $tmp -eq 0 ] || echo "$message"
    ret=$(( $ret + $tmp ))
	cleanup
}

cd `dirname $0`/..
puppet module install puppetlabs-stdlib --modulepath=`pwd`/../

run tests/init.pp "classic test failed"

run tests/dc.pp "AD test failed"

exit $ret
