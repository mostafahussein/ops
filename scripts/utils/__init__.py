#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import stat
import uuid
import signal
import logging
import subprocess

from os import path as osp

from logging import FileHandler
from logging.handlers import SysLogHandler
from logging.handlers import RotatingFileHandler


def ops_log_open(**kwargs):
    rootlog = kwargs.get("root", None)
    if rootlog:
        root = logging.getLogger()
    else:
        root = logging.getLogger(str(uuid.uuid4()))

    level = kwargs.get("level")
    if level is not None:
        root.setLevel(level)

    formatter = logging.Formatter(
        '%(asctime)s %(levelname)8s '
        '%(funcName)s(%(filename)s:%(lineno)s) : %(message)s')

    filename = kwargs.get("filename")
    if filename is not None:
        rotate = kwargs.get("rotate")
        if rotate:
            maxbytes = kwargs.get("maxbytes", 0)
            bakcount = kwargs.get("backupcount", 0)
            hdlr = RotatingFileHandler(filename,
                                       maxBytes=maxbytes,
                                       backupCount=bakcount)
        else:
            hdlr = FileHandler(filename)
    else:
        stream = kwargs.get("stream")
        hdlr = logging.StreamHandler(stream)
    hdlr.setFormatter(formatter)
    root.addHandler(hdlr)

    if "syslog" in kwargs:
        syslog = kwargs.get("syslog")
        assert(isinstance(syslog, dict))
        if "address" not in syslog:
            syslog['address'] = "/dev/log"
        syslog_level = syslog.get("level", level)
        syslog_ident = syslog.get("ident", "opslog")
        for arg in ("level", "ident"):
            if arg in syslog:
                syslog.pop(arg)
        hdlr = SysLogHandler(**syslog)
        syslog_formatter = logging.Formatter(' '.join((
            ''.join((syslog_ident, ':')),
            '%(levelname)8s %(funcName)s(%(filename)s:%(lineno)s) :'
            ' %(message)s')))
        hdlr.setFormatter(syslog_formatter)
        if syslog_level:
            hdlr.setLevel(syslog_level)
        root.addHandler(hdlr)

    if not kwargs.get("propagate", False):
        root.propagate = False

    return root


def check_dir(mode=0755, *args):
    """check directory, mkdir if not exist"""
    for d in args:
        d = osp.abspath(d)
        if not osp.exists(d):
            os.mkdir(d, mode)
        else:
            dmode = os.stat(d).st_mode
            if stat.S_ISDIR(dmode):
                dmode = stat.S_IMODE(dmode)
                if dmode != mode:
                    os.chmod(d, mode)
            else:
                raise Exception("file (%s) exist, but not directory" % (d,))


def exec_cmd(cmd):
    p = None
    ret = None
    try:
        p = subprocess.Popen(cmd,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
        out, err = p.communicate()
    except Exception as e:
        out, err = "", str(e)
    finally:
        if p:
            ret = p.wait()

    if ret is None:
        return ret, err
    elif ret != 0:
        sigdict = dict((-k, v) for v, k in signal.__dict__.iteritems()
                       if (
                           v.startswith('SIG') and
                           v not in ('SIG_DFL', 'SIG_IGN')))
        return ret, "(%s): %s" % (sigdict.get(ret, str(ret)), err)
    else:
        return 0, out

if __name__ == "__main__":
    ops_log = ops_log_open(syslog={'level': logging.CRITICAL})

    ops_log.warn("warn")
    ops_log.critical("critical")
    print exec_cmd(("sleep", "3600"))
