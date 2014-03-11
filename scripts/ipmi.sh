#!/bin/sh
#
# Change Password
#
# ./ipmi.sh -h HOST -p PASS user list
# ./ipmi.sh -h HOST -p PASS user set password 2 XXXXXXX
#
# Change network parameter
#
# ./ipmi.sh -h HOST -p PASS channel info 1
# ./ipmi.sh -h HOST -p PASS lan print 1
# ./ipmi.sh -h HOST -p PASS lan set 1 ipaddr X.X.X.X
#

# void die(int error, char *message)
die() {
    local ret="${1:-0}"
    shift

    echo "*** $*"
    exit $ret
}

ARGVS=$(getopt -o h:p:u: -- "$@") || die $? Getopt failed.
eval set -- "$ARGVS"

USER=root
HEXKEY=0000000000000000000000000000000000000000

while true; do
    case "$1" in
        -h) HOST=$2 ; shift 2 ;;
        -p) PASS=$2 ; shift 2 ;;
        -u) USER=$2 ; shift 2 ;;
        --) shift ; break ;;
        *) die 1 "getopt error" ;;
    esac
done

[ -z ${HOST} ] && die 1 "Missing host"
if [ -z ${PASS} ] && [ -z ${IPMI_PASSWORD} ] ; then
    die 1 "Missing password"
fi

CMD="/usr/sbin/ipmitool -I lanplus -H ${HOST} -U ${USER} -y ${HEXKEY}"

if [[ -z ${IPMI_PASSWORD} ]] ; then
    CMD=${CMD}" -P ${PASS}"
else
    CMD=${CMD}" -E"
fi

[ $# -lt 1 ] && {
    ${CMD} power status
    #${CMD} lan print
    #${CMD} chassis status
} || {
    ${CMD} $*
}

exit $?
