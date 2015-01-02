#! /usr/bin/env python
#  coding=utf-8
"""
read and parse syslog from stdin, feed to nagios for passive check
"""

import os
import sys
import pwd
import json
import stat
import getopt
import syslog
import resource
import tempfile
import traceback
from os import path as osp
from datetime import datetime


def getline_from_stdin():
    '''return line by read from stdin'''
    while True:
        l = sys.stdin.readline()
        if l:
            l = l.rstrip('\r\n')
            if l == "":
                continue
            yield l
        else:
            yield None


def send2nagios(host, svc, ret, text, time):
    '''send result to nagios'''
    if use_cmd:
        send2nagios_cmd(host, svc, ret, text, time)
    else:
        send2nagios_dir(host, svc, ret, text, time)


def send2nagios_cmd(host, svc, ret, text, time):
    func = send2nagios_cmd

    msg_host = "[{t}] PROCESS_HOST_CHECK_RESULT;{host};{ret};{text}\n"
    msg_svc = "[{t}] PROCESS_SERVICE_CHECK_RESULT;{host};{svc};{ret};{text}\n"

    if not hasattr(func, "cmd_fp"):
        func.cmd_fp = open(nagios_dst, 'w')

    if svc:
        msg = msg_svc.format(t=time, host=host, svc=svc, ret=ret, text=text)
    else:
        msg = msg_host.format(t=time, host=host, ret=ret, text=text)

    func.cmd_fp.write(msg)


def send2nagios_dir(host, svc, ret, text, time):
    msg_str = "### Passive Check Result File ###\n"   \
              "file_time={t}\n"                      \
              "\n"                                    \
              "### Nagios Service Check Result ###\n" \
              "# Time: Thu Dec 25 18:19:30 2014\n"    \
              "host_name={host}\n"                    \
              "{svc}"                                 \
              "check_type=1\n"                        \
              "check_options=0\n"                     \
              "scheduled_check=0\n"                   \
              "reschedule_check=0\n"                  \
              "latency=0.0\n"                         \
              "start_time={t}.0\n"                    \
              "finish_time={t}.0\n"                   \
              "early_timeout=0\n"                     \
              "exited_ok=1\n"                         \
              "return_code={ret}\n"                   \
              "output={text}\n"

    if svc:
        svc = "service_description={svc}\n".format(svc=svc)
    else:
        svc = ""
    msg = msg_str.format(t=time, host=host, svc=svc, ret=ret, text=text)

    (fd, fname) = tempfile.mkstemp(prefix='c', dir=nagios_dst)
    os.write(fd, msg)
    os.close(fd)

    open(".".join((fname, "ok")), "w+").close()


def check_args(use_cmd, use_dir, nagios_dst):
    if use_cmd and use_dir:
        return 1, "cmd/dir can't both used."
    elif not (use_cmd or use_dir):
        return 1, "one of cmd/dir must be used."

    if not nagios_dst:
        return 1, "destination of nagios [cmd|dir] must defined."
    else:
        if not osp.isabs(nagios_dst):
            return 1, "destination must be absolute path."
        else:
            if not osp.exists(nagios_dst):
                return 1, "dst `{0}' not found".format(nagios_dst)
            mode = os.stat(nagios_dst).st_mode
            if use_dir:
                if not stat.S_ISDIR(mode):
                    return 1, "destination is not a directory"
            else:
                if not stat.S_ISFIFO(mode):
                    return 1, "destination is not a fifo"

    return 0, "ok"

if __name__ == "__main__":

    if sys.hexversion < 0x2070000:
        syslog.openlog('log2nagios', syslog.LOG_PID, syslog.LOG_LOCAL3)
    else:
        syslog.openlog(ident='log2nagios',
                       logoption=syslog.LOG_PID,
                       facility=syslog.LOG_LOCAL3)

    use_dir = False
    use_cmd = False
    nagios_dst = None
    run_user = None

    try:
        opts, args = getopt.getopt(sys.argv[1:], '',
                                   ['cmd', 'dir', 'dst=', 'user='])
    except getopt.error, e:
        syslog.syslog(e)
        sys.exit(1)

    for opt, arg in opts:
        if opt in ('--cmd',):
            use_cmd = True
        elif opt in ('--dir',):
            use_dir = True
        elif opt in ('--dst',):
            nagios_dst = arg
        elif opt in ('--user',):
            run_user = arg
        else:
            syslog.syslog('unknown option {0}/{1}, ignored'.format(opt, arg))

    ret, msg = check_args(use_cmd, use_dir, nagios_dst)
    if ret != 0:
        syslog.syslog(syslog.LOG_ERR, msg)
        sys.exit(ret)

    if use_dir and run_user:
        resource.setrlimit(resource.RLIMIT_NOFILE, (102400,102400))
        runuser = pwd.getpwnam(run_user)
        os.setgid(runuser.pw_gid)
        os.setuid(runuser.pw_uid)
        os.umask(0022)

    # @todo catch json exception
    for line in getline_from_stdin():
        if not line:
            break

        timestamp = datetime.now().strftime('%s')

        try:
            log_data = json.loads(line)
            host = log_data.get('host', None)
            if host is None:
                syslog.syslog("host not found in '{0}'".format(line))
                continue
            msg = log_data.get('msg', {})
            domain = msg.get('domain', None)
            if domain:
                host = ".".join((host, domain))
                msg.pop('domain')
            if 'rand' in msg:
                msg.pop('rand')
            for k, v in msg.iteritems():
                if len(v) != 2 or               \
                   not isinstance(v[0], int) or \
                   v[0] < 0 or                  \
                   v[0] > 3:
                    syslog.syslog("malformed msg '{0}: '{1}'".format(k, v))
                    continue
                svc_name = k.upper()
                svc_ret = v[0]
                svc_text = v[1]
                syslog.syslog("{1}@{0} return {2}, '{3}'".format(host,
                                                                 svc_name,
                                                                 svc_ret,
                                                                 svc_text))
                send2nagios(host, svc_name, svc_ret, svc_text, timestamp)
            if msg:
                svc_text = "OK by passive notify from syslog"
                send2nagios(host, 'PING', 0, svc_text, timestamp)
                send2nagios(host, None, 0, svc_text, timestamp)

        except Exception, e:
            syslog.syslog(syslog.LOG_ERR, "{0}".format(line))
            syslog.syslog(syslog.LOG_ERR,
                          "{0}".format(traceback.format_exc()))

    sys.exit(0)
