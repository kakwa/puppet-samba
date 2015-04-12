#!/bin/sh

help(){
  cat <<EOF
usage: `basename $0` -d <dir> -g <group> -u <user> -m <mode>

creates home directory for samba users

EOF
  exit 1
}

while getopts ":hd:u:g:m:" opt; do
  case $opt in

    h) 
        help
        ;;
    d)
        DIR="$OPTARG"
        ;;
    u)
        USER="$OPTARG"
        ;;
    g)
        USER="$OPTARG"
        ;;
    m)
        MODE="$OPTARG"
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

if [ -z "$DIR" ]
then
    echo "Missing -d option"
    exit 1
fi

if ! [ -d "$DIR" ]
then
   mkdir -p "$DIR"
fi

if ! [ -z "$USER" ] && ! [ `stat -c %U "$DIR"` = "$USER" ]
then
  chown "${USER}" "$DIR"
fi 

if ! [ -z "$GROUP" ] && ! [ `stat -c %G "$DIR"` = "$GROUP" ]
then
  chgrp "$GROUP" "$DIR"
fi 

if ! [ -z "$MODE" ] && ! [ `stat -c %a "$DIR"` = "$MODE" ]
then
  chmod "$MODE" "$DIR"
fi 
