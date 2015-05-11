#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import shlex
from os import path as osp
from pprint import pprint

from utils import exec_cmd as exec_cmd


def gitversion(git_dir=None, local='HEAD', remote=None):
    git_option = ''
    if git_dir:
        git_option = "--git-dir={0}/.git --work-tree={0}".format(git_dir)

    outa = []

    cmd = shlex.split("git {0} rev-parse --short HEAD".format(git_option))
    ret, out =  exec_cmd(cmd)
    if ret != 0:
        return ret, ' '.join(outa)
    outa.append(out.strip())

    if not remote:
        get_head_name_cmd = shlex.split("git {0} rev-parse --abbrev-ref HEAD"
                                        .format(git_option))
        head_name = exec_cmd(get_head_name_cmd)[1].strip()
        remote = "origin/{0}".format(head_name)
    cmd = shlex.split("git {0} rev-list --left-right --count {1}...{2}"
                      .format(git_option, remote, local))
    ret, out =  exec_cmd(cmd)
    if ret != 0:
        return ret, ' '.join(outa)
    behind, ahead = [int(h) for h in out.strip().split('\t')]
    if ahead:
        outa.append('a{0}'.format(ahead))
    if behind:
        outa.append('b{0}'.format(behind))

    cmd = shlex.split('git {0} status --porcelain'.format(git_option))
    ret, out =  exec_cmd(cmd)
    if ret != 0:
        return ret, ' '.join(outa)
    if out: outa.append('*')

    return '-'.join(outa)


def stat_version(**kwargs):
    versions = {}

    for k, v in kwargs.items():
        t, args = v['type'], v['args']
        if t == "file":
            if osp.exists(args):
                versions[k] = open(args).read().strip()
            else:
                versions[k] = "null"
        elif t == 'git':
            versions[k]= gitversion(args,
                                    local=v.get('local', 'HEAD'),
                                    remote=v.get('remote', None))
        elif t in ("dpkg", "exec", "svn"):
            if t == "exec":
                cmd = args
            elif t == "svn":
                cmd = ("svnversion", "-c", args)
            elif t == "dpkg":
                cmd = ("dpkg-query", "-W", "-f=${Version}", args)
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
