{%- import_yaml "config/check_raid.yaml" as raid with context -%}
#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import sys
import syslog
import socket
import traceback
from utils import exec_cmd
from os import path as osp

utils_dir = osp.join(osp.dirname(osp.realpath(__file__)), "utils")
if utils_dir not in sys.path:
    sys.path.insert(0, utils_dir)

from notify import send_mail

if __name__ == "__main__":
    if sys.hexversion < 0x2070000:
        syslog.openlog('megacli', syslog.LOG_PID, syslog.LOG_LOCAL3)
    else:
        syslog.openlog(ident='megacli',
                       logoption=syslog.LOG_PID,
                       facility=syslog.LOG_LOCAL3)

    try:
        try:
            cmd = ['megacli', '-LDInfo', '-Lall', '-aALL', '-NoLog']
            ret, ld_info = exec_cmd(cmd)
            ld_status = re.findall('state\s+:\s(.+)', ld_info, re.I)
        except:
            ld_info = (traceback.format_exc(),)

        if not all(i == "Optimal" for i in ld_status):
            syslog.syslog(syslog.LOG_ERR,
                          "virtual disk is not in optimal state")
            hostname = socket.getfqdn()
            subject = u'[{{ raid.conf.subject }}] 主机（%s）检测到 RAID 设备故障' % (hostname,)
            fromaddr = "root@%s" % (hostname,)
            toaddr = {{ raid.conf.toaddr }}
            send_mail(fromaddr, toaddr, subject, ld_info, priority=1)
        else:
            syslog.syslog("virtual disk state is ok")

    except Exception, e:
        syslog.syslog(syslog.LOG_ERR, "%s" % traceback.format_exc())
