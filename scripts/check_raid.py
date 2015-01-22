{%- import_yaml "config/check_raid.yaml" as raid with context -%}
#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import sys
import getopt
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
        syslog.openlog('check_raid', syslog.LOG_PID, syslog.LOG_LOCAL3)
    else:
        syslog.openlog(ident='check_raid',
                       logoption=syslog.LOG_PID,
                       facility=syslog.LOG_LOCAL3)

    dev_dict = {
        'lsi': {
            'cmd': ('megacli', '-LDInfo', '-Lall', '-aALL', '-NoLog'),
            'rule': 'state\s+:\s(.+)',
            'ok': 'Optimal',
        },
        'hpa': {
            'cmd': ('hpacucli', 'ctrl', 'all', 'show', 'status'),
            'rule': 'Status:\s(.+)',
            'ok': 'OK',
        },
    }

    try:
        try:
            k_dev = None
            ld_status = None
            opts, args = getopt.getopt(sys.argv[1:], 'd:')
            for opt, arg in opts:
                if opt in ('-d'):
                    if not dev_dict.get(arg):
                        raise Exception('Unsupported device {0}'.format(arg))
                    k_dev = arg

            cmd = dev_dict[k_dev]['cmd']
            ret, ld_info = exec_cmd(cmd)
            ld_status = re.findall(dev_dict[k_dev]['rule'], ld_info, re.I)
        except getopt.error, e:
            ld_info = traceback.format_exc()
        except:
            ld_info = traceback.format_exc()

        if not (ld_status and \
            all(i == dev_dict[k_dev]['ok'] for i in ld_status)):
            syslog.syslog(syslog.LOG_ERR,
                          "virtual disk is not in optimal state")
            hostname = socket.getfqdn()
            subject = u'[{{ raid.subject }}] 主机（%s）检测到 RAID 设备故障' % (hostname,)
            fromaddr = "root@%s" % (hostname,)
            toaddr = {{ raid.toaddr }}
            send_mail(fromaddr, toaddr, subject, ld_info, priority=1)
        else:
            syslog.syslog("virtual disk state is ok")

    except Exception, e:
        syslog.syslog(syslog.LOG_ERR, "%s" % traceback.format_exc())
