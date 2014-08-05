#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import json
import gzip
import tempfile
import traceback
import subprocess

from os import path as osp
from datetime import datetime
from pprint import pprint as pprint

import sandbox


def run_rsync(cfgs, **kwargs):
    opts = ["rsync"]
    content = kwargs.get('content')
    log_fp = kwargs.get('log', sys.stdout)
    dry_run = kwargs.get('dry_run', True)

    if dry_run:
        opts.append("-n")

    for c in cfgs:
        src = c.get('src')
        dst = c.get('dst')
        if not (src and dst):
            content.append(">> rsync w/o src or dst defined: `%s'" % (c,))
            continue
        rsync_cmd = opts[:]
        if 'opts' in c:
            rsync_cmd.extend(c.get('opts'))
        rsync_cmd.extend((src, dst))

        log_fp.write(">>> begin @ %s, `%s'\n" %
                     (datetime.now(), " ".join(rsync_cmd)))
        log_fp.flush()

        if osp.exists(dst):
            sandbox.enable(dst)

        p = subprocess.Popen(rsync_cmd, stdout=log_fp, stderr=log_fp)
        try:
            ret = p.wait()
            if ret != 0:
                content.append(">> `%s' failed w/ %d\n" %
                               (" ".join(rsync_cmd), ret))
        except KeyboardInterrupt:
            p.terminate()

        sandbox.disable()

        log_fp.write(">>> end @ %s, `%s'\n\n" %
                     (datetime.now(), " ".join(rsync_cmd)))
        log_fp.flush()


def run_mysql(cfgs, **kwargs):
    opts = ["mysqldump"]
    content = kwargs.get('content')
    log_fp = kwargs.get('log', sys.stdout)
    dry_run = kwargs.get('dry_run', True)

    for c in cfgs:
        name = c.get('name')
        db = c.get('db', '--all-databases')
        dst = c.get('dst')
        if not name or not dst:
            content.append(">> mysqldump w/o dst defined: `%s'" % (c,))
            continue

        mysql_cmd = opts[:]
        if 'opts' in c:
            mysql_cmd.extend(c.get('opts'))
        mysql_cmd.extend((db,))

        log_fp.write(">>> begin @ %s, `%s'\n" %
                     (datetime.now(), " ".join(mysql_cmd)))
        log_fp.flush()

        filename = osp.join(dst, "%s-%s.mysql.gz" %
                            (datetime.now().strftime("%Y%m%d-%H%M"), name))

        saved_tmp = os.environ.get('TMPDIR')

        if osp.isdir(dst):
            sandbox.enable(dst)
        else:
            content.append(">> `%s' not exists or is not directory" % (dst,))
            continue

        if dry_run:
            log_fp.write(">>> will save file to %s\n" %
                         (osp.join(dst, filename)))
        else:
            if c.get('tmp'):
                os.environ['TMPDIR'] = c.get('tmp')
            dump_fp = tempfile.TemporaryFile()
            p = subprocess.Popen(mysql_cmd, stdout=dump_fp, stderr=log_fp)
            try:
                ret = p.wait()
                if ret != 0:
                    content.append(">> `%s' failed w/ %d\n" %
                                   (" ".join(mysql_cmd), ret))
                else:
                    gzfile = gzip.open(filename, "wb")
                    dump_fp.seek(0, os.SEEK_END)
                    s0 = dump_fp.tell()
                    dump_fp.seek(0, os.SEEK_SET)
                    gzfile.writelines(dump_fp)
                    gzfile.close()
                    dump_fp.close()
                    s1 = os.stat(filename).st_size
                    log_fp.write(">>> save file to %s, size %d (%.0f%%)\n" %
                                 (osp.join(dst, filename), s1, s1*100.0/s0))
            except KeyboardInterrupt:
                p.terminate()

        if os.environ.get('TMPDIR'):
            if saved_tmp:
                os.environ['TMPDIR'] = saved_tmp
            else:
                os.environ.pop('TMPDIR')

        sandbox.disable()

        log_fp.write(">>> end @ %s, `%s'\n\n" %
                     (datetime.now(), " ".join(mysql_cmd)))
        log_fp.flush()


def run_command(cfgs, **kwargs):
    content = kwargs.get('content')
    log_fp = kwargs.get('log', sys.stdout)
    dry_run = kwargs.get('dry_run', True)

    for c in cfgs:
        sandbox_dir = c.get('dir')
        command = c.get('cmd')
        run_cmd = []

        if not command or not sandbox_dir:
            content.append(">> command and dir must both be defined: `%s'" %
                           (c,))
            continue

        now = datetime.now().strftime("%Y%m%d-%H%M")

        for c in command:
            c = c % locals()
            run_cmd.append(c)

        log_fp.write(">>> begin @ %s, `%s'\n" %
                     (datetime.now(), " ".join(command)))

        if dry_run:
            log_fp.write(">>> will run command `%s'\n" % (" ".join(run_cmd)))
        else:
            sandbox.enable(sandbox_dir)
            p = subprocess.Popen(run_cmd, stdout=log_fp, stderr=log_fp)
            try:
                ret = p.wait()
                if ret != 0:
                    content.append(">> `%s' failed w/ %d\n" %
                                   (" ".join(run_cmd), ret))
                else:
                    log_fp.write(">>> command `%s` success\n" %
                                 " ".join(run_cmd))
            except KeyboardInterrupt:
                p.terminate()

        sandbox.disable()

        log_fp.write(">>> end @ %s, `%s'\n" %
                     (datetime.now(), " ".join(command)))
        log_fp.flush()
