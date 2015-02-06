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
        'lsi': (
            {
                'cmd': ('megacli', '-LDInfo', '-Lall', '-aALL', '-NoLog'),
                'rule': 'state\s+:\s(\w.+)',
                'ok': 'Optimal',
            },
        ),
        'hpa': (
            {
                'cmd': ('hpacucli', 'ctrl', 'all', 'show', 'status'),
                'rule': 'Status:\s(\w+)',
                'ok': 'OK',
            },
            {
                'cmd': ('hpacucli', 'ctrl', 'all', 'show', 'config'),
                'rule': '\(.+\, (\w+)\)',
                'ok': 'OK',
            },
        ),
    }

    try:
        raid_info = []
        raid_status = []
        try:
            k_dev = None
            opts, args = getopt.getopt(sys.argv[1:], 'd:')
            for opt, arg in opts:
                if opt in ('-d'):
                    if not dev_dict.get(arg):
                        raise Exception('Unsupported device {0}'.format(arg))
                    k_dev = arg
            for v in dev_dict[k_dev]:
                cmd = v['cmd']
                ret, output = exec_cmd(cmd)
                raid_info.append(output)
                result = {v['ok']: re.findall(v['rule'], output, re.I)}
                raid_status.append(result)

        except getopt.error, e:
            raid_info.append(traceback.format_exc())
        except:
            raid_info.append(traceback.format_exc())

        raid_ok = False
        if raid_status:
            raid_ok = True
            for d in raid_status:
                for k, v in d.items():
                    if not (d and all(i == k for i in v)):
                        raid_ok = False
                        break
        if not raid_ok:
            syslog.syslog(syslog.LOG_ERR,
                          "raid array is not in optimal state")
            hostname = socket.getfqdn()
            subject = u'[{{ raid.subject }}] 主机（%s）检测到 RAID 设备故障' % (hostname,)
            fromaddr = "root@%s" % (hostname,)
            toaddr = {{ raid.toaddr }}
            send_mail(fromaddr, toaddr, subject,
                      "\n".join(raid_info), priority=1)
        else:
            syslog.syslog("raid array is in ok state")

    except Exception, e:
        syslog.syslog(syslog.LOG_ERR, "%s" % traceback.format_exc())
