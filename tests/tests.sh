#!/bin/sh

cleanup(){
    # some clean up
    apt-get purge -y winbind
    apt-get purge -y samba-common
    apt-get autoremove -y
    pkill -9 samba
    pkill -9 smb
    pkill -9 nmd
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

echo
echo "#####################################################"
echo "#####################################################"
echo

run tests/init.pp "classic test failed"

echo
echo "#####################################################"
echo "#####################################################"
echo

cleanup

echo
echo "#####################################################"
echo "#####################################################"
echo

run tests/dc.pp "AD test failed"

netstat -apn | grep ':389'; ret=$(( $ret + $? ))
netstat -apn | grep ':53';  ret=$(( $ret + $? ))
netstat -apn | grep ':636'; ret=$(( $ret + $? ))
netstat -apn | grep ':464'; ret=$(( $ret + $? ))

echo
echo "#####################################################"
echo "#####################################################"
echo
[ $tmp -eq 0 ] || echo "AD doesn't have all listening ports"
echo
echo "#####################################################"
echo "#####################################################"

cleanup

exit $ret
