#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import json
import subprocess


def salt_diff(cmd):
    salt_ret = os.tmpfile()
    p = subprocess.Popen(cmd, stdout=salt_ret)
    p.wait()
    salt_ret.seek(0, os.SEEK_SET)
    salt_json = json.load(salt_ret)
    salt_ret.close()

    results = {}
    content = []
    for host, states in salt_json.items():
        diffs = {}
        if isinstance(states, list):
            diffs['salt'] = states[0]
        elif isinstance(states, unicode):
            diffs['salt'] = states
        elif isinstance(states, dict):
            for module, state in states.items():
                if not state.get('result'):
                    diffs[module] = state.get('comment')
        else:
            raise Exception("Unknown type `%s'" % (type(states),))
        if diffs:
            content.append("> %s" % (host,))
            for k, v in diffs.items():
                content.append(">> %s" % (k,))
                for v0 in v.split('\n'):
                    content.append(">>> %s" % (v0,))

    return content
