#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import yaml
import socket
import syslog
import argparse
import traceback

reload(sys)
sys.setdefaultencoding('utf-8')

from os import path as osp
from jinja2 import Template
from pprint import pprint as pprint

utils_dir = osp.join(osp.dirname(osp.realpath(__file__)), "utils")
if utils_dir not in sys.path:
    sys.path.insert(0, utils_dir)

import sandbox
import backup_helper
from notify import send_mail


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Password Expiration Check')
    parser.add_argument("--do",
                        default=True,
                        help='Send email',
                        action="store_false")
    args = parser.parse_args()
    dry_run = args.do

    sandbox.setup()

    syslog.openlog(ident='backup',
                   logoption=syslog.LOG_PID,
                   facility=syslog.LOG_LOCAL3)

    content = []

    if sys.stdout.isatty():
        log_fp = sys.stdout
    else:
        log_fp = os.tmpfile()

    try:
        cfg_yaml = osp.join(osp.dirname(osp.realpath(__file__)),
                            "backup.yaml")
        template = Template(open(cfg_yaml, "r").read())
        cfg_bak = yaml.load(template.render())

        for k, cfgs in cfg_bak.get('backups', {}).items():
            action = "".join(("run_", k))
            if not hasattr(backup_helper, action):
                content.append(">> unsupported action %s\n" % (k,))
                continue
            bak_act = ".".join(("backup_helper", action))
            eval(bak_act)(cfgs, content=content, log=log_fp, dry_run=dry_run)

    except:
        content.append(">> uncatched exception:\n%s\n" %
                       (traceback.format_exc(),))

    if sys.stdout.isatty():
        if content:
            print("".join(content))
        sys.exit(0)
    else:
        log_fp.seek(0, os.SEEK_SET)

    if content:
        content.insert(0, ">>> Error Information\n")
        content.append("\n")
    content.extend(log_fp.readlines())

    hostname = socket.getfqdn()
    subject = " ".join((u'[备份日志]',
                        hostname,
                        cfg_bak.get('config', {}).get('title', '')))
    fromaddr = "root@%s" % (hostname,)
    toaddr = ("it@intra.knownsec.com",)
    send_mail(fromaddr, toaddr, subject, "".join(content),
              priority=1)
