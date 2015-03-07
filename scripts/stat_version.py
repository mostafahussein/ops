#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
from os import path as osp
from pprint import pprint

from utils import exec_cmd as exec_cmd


def stat_version(**kwargs):
    versions = {}

    for k, v in kwargs.items():
        t, args = v['type'], v['args']
        if t == "file":
            if osp.exists(args):
                versions[k] = open(args).read().strip()
            else:
                versions[k] = "null"
        elif t in ("dpkg", "exec", "svn", "git"):
            if t == "exec":
                cmd = args
            elif t == "svn":
                cmd = ("svnversion", "-c", args)
            elif t == "dpkg":
                cmd = ("dpkg-query", "-W", "-f=${Version}", args)
            elif t == "git":
                cmd = ("git", "--git-dir={0}/.git".format(args),
                        "--work-tree={0}".format(args),
                        "rev-parse", "--short", "HEAD")
            ret, out = exec_cmd(cmd)
            versions[k] = out.strip()
        else:
            versions[k] = "TYPE `%s' UNKNOWN" % t

    return versions


if __name__ == "__main__":
    import os
    import yaml
    yastat_cfg = yaml.load(open(osp.join(os.getcwd(), "yastatd.yaml"), "r"))
    if yastat_cfg.get("version"):
        print stat_version(**yastat_cfg["version"])
