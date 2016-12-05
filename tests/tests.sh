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
[ $tmp -eq 0 ] || echo "AD doesn't have all listening ports"
echo
echo "#####################################################"
echo "#####################################################"


echo
echo "#####################################################"
echo "#####################################################"
echo


# testing password setting for samba AD password
run tests/smb_user.pp "AD test failed"

netstat -apn | grep ':389'; ret=$(( $ret + $? ))
netstat -apn | grep ':53';  ret=$(( $ret + $? ))
netstat -apn | grep ':636'; ret=$(( $ret + $? ))
netstat -apn | grep ':464'; ret=$(( $ret + $? ))

####
# test the force_password = false setting
# check that we can connect
smbclient '//localhost/netlogon' "c0mPL3xe_P455woRd" -Utest2 -c ls || ret=1
# reset password
samba-tool 'user', setpassword test2 --newpassword "c0mPL3xe_P455woRd2" -d 1 || ret=1
# reapply (should not change the passowrd for user test2
run tests/smb_user.pp "AD test failed"
# connect with puppet defined password should fail
smbclient '//localhost/netlogon' "c0mPL3xe_P455woRd" -Utest2 -c ls && ret=$(( $ret + $1 ))
# connect with manually defined password should successed
smbclient '//localhost/netlogon' "c0mPL3xe_P455woRd2" -Utest2 -c ls && ret=$(( $ret + $1 ))
###

echo
echo "#####################################################"
echo "#####################################################"
echo
[ $tmp -eq 0 ] || echo "SMB_USER failed"
echo


cleanup >/dev/null 2>&1

exit $ret
