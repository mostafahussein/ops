#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import json
import traceback
import subprocess

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

        if os.path.exists(dst):
            sandbox.enable(dst)

        p = subprocess.Popen(rsync_cmd, stdout=log_fp, stderr=log_fp)
        ret = p.wait()
        if ret != 0:
            content.append(">> `%s' failed w/ %d\n" %
                           (" ".join(rsync_cmd), ret))

        sandbox.disable()

        log_fp.write(">>> end @ %s, `%s'\n\n" %
                     (datetime.now(), " ".join(rsync_cmd)))
        log_fp.flush()
