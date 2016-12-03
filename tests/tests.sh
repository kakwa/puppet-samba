#!/bin/sh

cleanup(){
    # some clean up
    /etc/init.d/samba stop
    /etc/init.d/samba-ad-dc stop
    apt-get purge -y winbind
    apt-get purge -y samba-common
    apt-get autoremove -y
    pkill -9 samba
    pkill -9 smb
    pkill -9 nmb
    rm -f /usr/local/bin/additional-samba-tool
    rm -f /usr/local/bin/smb-create-home.sh
    rm -rf /var/run/samba/
}

run(){
    pp=$1
    message=$2
    puppet apply --certname=ad.example.org $pp --modulepath=`pwd`/../ --debug --color=false
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

cleanup >/dev/null 2>&1

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
[ $tmp -ne 0 ] || echo "AD doesn't have all listening ports"
echo
echo "#####################################################"
echo "#####################################################"

cleanup >/dev/null 2>&1

exit $ret
