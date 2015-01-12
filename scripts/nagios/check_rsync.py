#!/usr/bin/env python
# -*- coding: utf-8 -*-
# pylint: disable=redefined-outer-name
import sys
from os import path as osp

sys.path.insert(0, osp.dirname(osp.dirname(osp.realpath(__file__))))
from utils import nagios
from utils import rsync


def check_rsync(host):
    module, exit_code = rsync.get_rsync_status(host)
    exit_message = rsync.get_rsync_exit_message(exit_code)
    if exit_code in (10,):
        ret = nagios.STATE_CRITICAL
    elif exit_code in (0, 5):
        ret = nagios.STATE_OK
    else:
        ret = nagios.STATE_WARNING
    msg = "RSYNC %s -- %s of %s" % (nagios.STATE_STR[ret],
                                    exit_message, module)
    return (ret, msg)


def getargs():
    parser = argparse.ArgumentParser(description="check rsync service")
    parser.add_argument('-H', '--host', dest="host",
                        required=True, help="host")
    return parser.parse_args()


if __name__ == '__main__':
    # pylint: disable=superfluous-parens
    import argparse
    args = getargs()
    host = args.host
    ret, msg = check_rsync(host)
    print(msg)
    sys.exit(ret)
