#!/bin/sh

cleanup(){
    # some clean up
    apt-get purge -y samba-common winbind
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
}

cd `dirname $0`/..
puppet module install puppetlabs-stdlib --modulepath=`pwd`/../

run tests/init.pp "classic test failed"

cleanup

run tests/dc.pp "AD test failed"

netstat -apn | grep -q ':389'; ret=$(( $ret + $? ))
netstat -apn | grep -q ':53';  ret=$(( $ret + $? ))
netstat -apn | grep -q ':636'; ret=$(( $ret + $? ))
netstat -apn | grep -q ':464'; ret=$(( $ret + $? ))

[ $tmp -eq 0 ] || echo "AD doesn't have all listening ports"

cleanup

exit $ret
