#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import urllib2


def stat_nginx(**kwargs):
    """
    see http://wiki.nginx.org/HttpStubStatusModule
    """

    _stat = {}

    module = kwargs.get('module')
    url = kwargs.get('url')

    if module == "stub_status":
        """
        parse output like:
            Active connections: 1
            server accepts handled requests
             2235 2235 3541
             Reading: 0 Writing: 1 Waiting: 0
        """

        out = urllib2.urlopen(url).read()
        pat = "server accepts handled requests\n" \
              "\s(?P<cps>\d+)\s(?P<hcps>\d+)\s(?P<rps>\d+)"
        m = re.search(pat, out)
        _stat = {}
        if m is None:
            raise Exception("Can't get cps/hcps/rps by matching output")
        for k, v in m.groupdict().iteritems():
            _stat[k] = int(v)
    else:
        raise Exception("Unsupported module: %s" % module)

    return _stat

if __name__ == "__main__":
    print stat_nginx(module='stub_status', url='http://127.0.0.1:1111/status')
