#!/bin/bash

export SANDBOX=/usr/lib64/libsandbox.so

die()
{
    local ret="${1:-0}"
    shift

    echo "*** $*"
    exit $ret
}

for f in /usr/lib64/bash/sleep /usr/lib/bash/sleep ; do
    if [ -x ${f} ] ; then
        enable -f ${f} sleep
        break
    fi
done

[ -s /usr/lib64/libsandbox.so ] && {
    export SANDBOX=/usr/lib64/libsandbox.so
}

set_sandbox()
{
    [ -z "${SANDBOX}" -o ! -f "${SANDBOX}" ] && return

    export LD_PRELOAD=${SANDBOX}
    export SANDBOX_ON=1
    export SANDBOX_LOG=/tmp/sandbox.log
    export SANDBOX_READ=/
    export SANDBOX_ACTIVE="armedandready"
}

unset_sandbox()
{
    unset LD_PRELOAD
}

enable_sandbox()
{
    local dir=$1

    [ -z "${SANDBOX}" -o ! -f "${SANDBOX}" ] && return

    export SANDBOX_WRITE="${dir}"
}

disable_sandbox()
{
    unset SANDBOX_WRITE
}

get_proc_dir()
{
    local PIDFILE=$1

    if [ -s ${PIDFILE} ] ; then
        local pid=$(< $1)
        if [ ! -z ${pid} ] ; then
            X_PROCDIR="/proc/${pid}"
            return 0
        fi
    fi

    return 1
}

log_and_run()
{
    local loglevel=local4.notice

    eval $*
    ret=$?
    if [[ $ret -ne 0 ]] ; then
        loglevel=local4.crit
    fi
    logger -p ${loglevel} -t ${LOGGER_TAG:-unknown} -- "return $ret from cmd: $*"
    return $ret
}

function hexdomain()
{
    local hexdomain=""
    local domain=$1

    OLDIFS=${IFS}
    IFS=.

    for a in ${domain} ; do
        args="printf "
        for (( i=0; i<=${#a}; i++ )); do
            args=${args}"%02x"
        done
        args=${args}" ${#a}"
        for (( i=0; i<${#a}; i++ )); do
            args=${args}" ""\'${a:$i:1}"
        done
        hexdomain=${hexdomain}$(eval ${args})
    done

    IFS=${OLDIFS}

    echo -n ${hexdomain}
}

check_service()
{
    local PROG=$1
    local CMD=$2
    local SVC=$3
    local PCOUNT=1
    shift 3

    if [ $# -gt 0 ] ; then
        local PCOUNT=$1
        shift
    fi

    service ${SVC} status
    if [ $? -ne 0 ] ; then
        logger -i -p local3.err -t "$PROG" "${SVC} die, try restart"
        service ${SVC} restart
        if [ $? -ne 0 ] ; then
            logger -i -p local3.emerg -t "$PROG" "${SVC} restart failed, try again later"
        fi
        return
    fi

    if [[ ! -z ${CMD} ]] ; then
        pids=($(pgrep -f "${CMD}"))
        if [ $? -ne 0 ] ; then
            logger -i -p local3.emerg -t "$PROG" "${SVC} started, but process mismatch"
            service ${SVC} restart
            if [ $? -ne 0 ] ; then
                logger -i -p local3.emerg -t "$PROG" "${SVC} restart failed, try again later"
            fi
        else
            local pcount=${#pids[@]}
            if [ $pcount -lt $PCOUNT ] ; then
                logger -i -p local3.emerg -t "$PROG" "${SVC} started, but process count mismatch"
                service ${SVC} restart
                if [ $? -ne 0 ] ; then
                    logger -i -p local3.emerg -t "$PROG" "${SVC} restart failed, try again later"
                fi
            fi
        fi
    fi
}
