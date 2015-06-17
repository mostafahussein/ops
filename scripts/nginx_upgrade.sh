#!/bin/bash
#
# nginx master signal handler:
#
# TERM, INT : exit immediately
# QUIT      : graceful shutdown the old master process
# HUP       : restart worker w/ new config, old worker exit
# USR1      : reopen log file
# USR2      : upgrade nginx binary, start a new master and worker
# WINCH     : graceful shutdown of worker processes
#
# see: http://nginx.org/en/docs/control.html#upgrade
#

function check_nginx()
{
    [[ $# < 2 ]] && return 1

    local pid="$1"

    if [ "${pid}" != "" -a -d /proc/${pid} ] ; then
        local cmdline=$(< /proc/${pid}/cmdline)
        if [[ "${cmdline}" =~ ^nginx:\ master\ process ]] ; then
            return 0
        fi
    fi

    return 1
}

function check_nginx_config()
{
    nginx -t -q > /dev/null 2>&1
    return
}

if ! check_nginx_config ;then
    nginx -t
    echo "!! nginx config test failed, please correct errors above"
    exit 1
fi

pidfile="/var/run/nginx.pid"
opidfile="/var/run/nginx.pid.oldbin"

if [ ! -f "$pidfile" ]; then
    echo "!! nginx pid file not found, exit now"
    exit 1
fi

if [ -f "$opidfile" ]; then
    echo "!! nginx old pid file found, please check"
    exit 1
fi

pid=$(< "$pidfile")

echo ">> Found running nginx master w/ pid ${pid}"
echo ">> Try to start a new nginx master and worker process"
kill -USR2 $pid
while [ 1 ] ; do
    sleep 1
    if [ ! -f "${opidfile}" ] ; then
        echo "!! New process not started yet, ${opidfile} not found, wait 1s"
        continue
    fi
    if [ ! -f "${pidfile}" ] ; then
        echo "** new process not started yet, wait 1s"
        continue
    fi
    npid=$(< $pidfile)
    if check_nginx ${npid} -a check_nginx ${pid} ; then
        echo ">> New process started w/ pid ${npid}"
        echo ">> Gracefully shutdown the old worker processes"
        kill -WINCH $pid
        break
    fi
done

while [ 1 ] ; do
    wcount=$(ps -eo pid,ppid,command | \
        awk -v ppid=${pid} \
        'BEGIN {count=0} ($2==ppid && $3=="nginx:" && $4=="worker") { count++; } END {print count}')
    if [ "$wcount" = "0" ]; then
        kill -QUIT $pid
        echo ">> Gracefully shutdown the old master processes"
        break
    else
        echo ">> ${wcount} old work process still running, wait 1s"
    fi
    sleep 1
done

echo ">> Waiting for the old master process to exit"
while [ 1 ] ; do
    check_nginx ${pid} || {
        echo ">> Upgrade finish, new master pid is ${npid}"
        break
    }
    sleep 1
done

exit 0
