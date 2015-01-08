#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys

STATE_OK = 0
STATE_WARNING = 1
STATE_CRITICAL = 2
STATE_UNKNOWN = 3

STATE_STR = ["OK", "WARNING", "CRITICAL", "UNKNOWN"]

def do_exit(state, msg):
    print(msg % (STATE_STR[state],))
    sys.exit(state)

def validate(target, warning_v, critical_v, reverse=False):
    validated = True
    if target in ('load', 'disk'):
        for i in xrange(len(warning_v)):
            if critical_v[i] < warning_v[i]:
                validated = False
                break
    else:
        if critical_v < warning_v:
            validated = False
    flag = "<" if reverse else ">"
    if not validated:
        do_exit(STATE_UNKNOWN, "%%s -- %s" %
                " ".join(('value of "warning"', flag, '"critical"')))

def value_compare(target, v, warning_v, critical_v, msg):
    if v != None:
        state = STATE_OK
        if target in ('load', 'disk'):
            for i in xrange(len(warning_v)):
                if v[i] > critical_v[i]:
                    state = STATE_CRITICAL
                    break
                elif v[i] > warning_v[i]:
                    state = STATE_WARNING
                    break
        else:
            if v > critical_v:
                state = STATE_CRITICAL
            elif v > warning_v:
                state = STATE_WARNING
    else:
        state = STATE_UNKNOWN
    do_exit(state, msg)

if __name__ == '__main__':
    validate("cpu", 10, 20)
    value_compare("cpu", 30, 40, 50, "CPU %%s -- CPU Usage %s" % (30))
    do_exit(STATE_OK, "TARGET %%s -- %s" % ("aa",))
