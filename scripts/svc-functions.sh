#!/bin/bash

export SANDBOX=/usr/lib64/libsandbox.so

NOW_DATETIME=$(date +%Y%m%d-%H%M)
NOW_DATE=${NOW_DATETIME%-*}
NOW_DATE_HOUR=${NOW_DATETIME:0:-2}

die() {
    local ret="${1:-0}"
    shift

    echo "*** $*"
    exit $ret
}

set_sandbox()
{
    [ ! -f ${SANDBOX} ] && {
        echo "!!! CAUTION: Sandbox not found."
        return
    }

    export LD_PRELOAD=${SANDBOX}
    export SANDBOX_ON=1
    export SANDBOX_LOG=/tmp/sandbox.log
    export SANDBOX_READ=/
    export SANDBOX_ACTIVE="armedandready"
}

enable_sandbox()
{
    local dir=$1

    export SANDBOX_WRITE="${dir}"
}

disable_sandbox()
{
    unset SANDBOX_WRITE
}

# do_rsync src dst [rsync options]
do_rsync()
{
    if [ $# -lt 2 ] ; then
        echo "do_rsync src dst"
        return
    fi

    local src=$1
    local dst=$2
    shift 2

    if [ -d "${src}" -a -d "${dst}" ] ; then
        echo "!!! both src and dst are directory, ignore"
        return
    fi

    if [ -d "${dst}" ] ; then
        dir=$(realpath ${dst})
        pushd "${dir}"
        if [ "$(pwd)" != "${dir}" ] ; then
            echo "!!! can't cd to ${dir}"
            return
        fi
        enable_sandbox ${dir}
    fi

    echo ">>> Sync from ${src} to ${dst}, begin @ $(date)"
    rsync ${RSYNC_OPTS} $* ${src} ${dst}
    echo ">>> Sync end @ $(date)"

    if [ -d "${dst}" ] ; then
        disable_sandbox
        popd
    fi

    return
}
