#!/bin/sh

help(){
  cat <<EOF
usage: `basename $0` -[nCDc]

Test script for kakwa/puppet-samba module

arguments:
  -n: disable cleaning
  -c: do only cleaning, no tests
  -C: enable samba classic tests
  -D: enable samba AD/DC tests
EOF
  exit 1
}

NO_CLEAN=0
CLASSIC_TEST=0
DC_TEST=0
CLEAN_ONLY=0

while getopts ":hCDnc" opt; do
  case $opt in

    h)
        help
        ;;
    n)
        NO_CLEAN=1
        ;;
    C)
       CLASSIC_TEST=1
       ;;
    D)
       DC_TEST=1
       ;;
    c)
       CLEAN_ONLY=1
       ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        help
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        help
        exit 1
        ;;
  esac
done


cleanup(){

    if [ $NO_CLEAN -eq 1 ]
    then
        echo "Cleaning step skipped"
	return
    fi

    # some clean up
    /etc/init.d/samba stop
    /etc/init.d/samba-ad-dc stop
    apt-get purge -y winbind
    apt-get purge -y samba-common
    apt-get autoremove -y
    yum erase -y samba samba-common-libs samba-client-libs samba-common samba-libs samba-winbind samba-winbind-module
    pkill -9 samba
    pkill -9 smb
    pkill -9 nmb
    rm -f /usr/local/bin/additional-samba-tool
    rm -f /usr/local/bin/smb-create-home.sh
    rm -rf /var/run/samba/
    rm -rf /srv/test
}

exit_error(){
    msg=$1
    echo $msg
    cleanup >/dev/null 2>&1
    exit 1
}

run(){
    pp=$1
    message=$2
    puppet apply --certname=ad.example.org $pp --modulepath=`pwd`/modules --color=false --detailed-exitcodes
    ret=$?
    [ $ret -eq 4 ] && exit_error "$message"
    [ $ret -eq 6 ] && exit_error "$message"
}

if [ $CLEAN_ONLY -eq 1 ]
then
     echo "Cleaning up, and exiting fater"
     cleanup
     exit 0
fi

if [ $CLASSIC_TEST -eq 1 ]
then
    cd `dirname $0`/..
    mkdir `pwd`/modules
    puppet module install puppetlabs-stdlib --modulepath=`pwd`/modules
    puppet module install herculesteam-augeasproviders_pam --modulepath=`pwd`/modules
    ln -s ../ ./modules/samba

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
fi


if [ $DC_TEST -eq 1 ]
then
    run tests/dc.pp "AD test failed"


    sleep 10

    netstat -apn | grep ':389' || exit_error "should listen on 389"
    netstat -apn | grep ':53'  || exit_error "should listen on 53"
    netstat -apn | grep ':636' || exit_error "should listen on 636"
    netstat -apn | grep ':464' || exit_error "should listen on 464"

    echo
    echo "#####################################################"
    echo "#####################################################"
    echo

    echo
    echo "#####################################################"
    echo "#####################################################"
    echo


    # testing password setting for samba AD password
    run tests/smb_user.pp "smb_user test failed (apply 1)"


    netstat -apn | grep ':389' || exit_error "should listen on 389"
    netstat -apn | grep ':53'  || exit_error "should listen on 53"
    netstat -apn | grep ':636' || exit_error "should listen on 636"
    netstat -apn | grep ':464' || exit_error "should listen on 464"

    ####
    # test the force_password = false setting
    # check that we can connect
    smbclient '//localhost/netlogon' "c0mPL3xe_P455woRd" -Utest2 -c ls || exit_error "failed to login 1 test2"
    # reset password (don't know why, but it needs to be set 2 times to invalidate auth cache with previous password)
    samba-tool 'user' setpassword test2 --newpassword "c0mPL3xe_P455woRd2" -d 1 || exit_error "failed set password test2"
    samba-tool 'user' setpassword test2 --newpassword "c0mPL3xe_P455woRd2" -d 1 || exit_error "failed set password test2"
    samba-tool 'user' setpassword test3 --newpassword "c0mPL3xe_P455woRd2" -d 1 || exit_error "failed set password test3"
    samba-tool 'user' setpassword test3 --newpassword "c0mPL3xe_P455woRd2" -d 1 || exit_error "failed set password test3"
    # reapply (should not change the passowrd for user test2
    run tests/smb_user.pp "smb_user test failed (apply 2)"
    # need to remove authentication cache (otherwise old password works...)
    sleep 60
    # connect with puppet defined password should fail
    smbclient '//localhost/netlogon' "c0mPL3xe_P455woRd" -Utest2 -c ls && exit_error "succeded to login (not expected) test2"
    # connect with manually defined password should successed
    smbclient '//localhost/netlogon' "c0mPL3xe_P455woRd2" -Utest2 -c ls || exit_error "failed to login 2 test2"
    smbclient '//localhost/netlogon' "c0mPL3xe_P455woRd2" -Utest3 -c ls || exit_error "failed to login 2 test3"
    ###

    echo
    echo "#####################################################"
    echo "#####################################################"
    echo

    cleanup >/dev/null 2>&1

    echo
    echo "#####################################################"
    echo "#####################################################"
    echo

    run tests/no_winbind.pp "winbind test failed"

    echo
    echo "#####################################################"
    echo "#####################################################"
    echo

    cleanup >/dev/null 2>&1

    echo
    echo "#####################################################"
    echo "#####################################################"
    echo

    run tests/smb_acl.pp "acl test failed"

    echo
    echo "#####################################################"
    echo "#####################################################"
    echo

fi

cleanup >/dev/null 2>&1

exit 0
