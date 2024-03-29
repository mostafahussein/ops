#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import json
import traceback
import subprocess


def salt_diff(cmd):
    salt_ret = os.tmpfile()
    p = subprocess.Popen(cmd, stdout=salt_ret, stderr=salt_ret)
    p.wait()
    salt_ret.seek(0, os.SEEK_SET)
    try:
        salt_json = json.load(salt_ret)
    except:
        salt_ret.seek(0, os.SEEK_SET)
        content = []
        for l in (salt_ret.readlines()):
            content.append(" ".join([">", l]))
        content.append(traceback.format_exc())
        return content
    finally:
        salt_ret.close()

    results = {}
    content = []
    for host, states in salt_json.items():
        diffs = {}
        if isinstance(states, list):
            diffs['salt'] = "\n".join(states)
        elif isinstance(states, unicode):
            diffs['salt'] = states
        elif isinstance(states, dict):
            for module, state in states.items():
                if not state.get('result'):
                    if not diffs.get(module):
                        diffs[module] = {}
                    diffs[module]['comment'] = state.get('comment')
                    if state.get('changes'):
                        diffs[module]['changes'] = state.get('changes')
        else:
            raise Exception("Unknown type `%s'" % (type(states),))
        if diffs:
            content.append("> %s" % (host,))
            salt_format(diffs, content, "")

    return content


def salt_format(obj, out, indent):
    if isinstance(obj, basestring):
        for v in obj.split('\n'):
            out.append("%s> %s" % (indent, v))
    elif isinstance(obj, dict):
        for k,v in obj.iteritems():
            salt_format(k, out, "%s>" % (indent,))
            salt_format(v, out, "%s>" % (indent,))
    else:
        out.append("%s> %s unsupported yet" % (indent, type(obj)))
        out.append("%s> %s" % (indent, obj))
