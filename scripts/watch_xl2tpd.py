#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
only work on Linux

TODO:
  * platform support for restart service

'''
import os
import time
import socket
import argparse
import logging
import traceback
from subprocess import check_output

from utils import exec_cmd, ops_log_open
from utils.notify import send_mail as _send_mail

PAGE_SIZE = os.sysconf('SC_PAGESIZE')  # bytes


def mem_info_of_pid(pid):
    _proc_stat = '/proc/{0}/stat'.format(pid)
    PROC_STAT = ('state', 'ppid', 'pgrp', 'session',
                 'tty_nr', 'tpgid', 'flags', 'minflt', 'cminflt', 'majflt',
                 'cmajflt', 'utime', 'stime', 'cutime', 'cstime', 'priority',
                 'nice', 'num_threads', 'itrealvalue', 'starttime',
                 'vsize', 'rss', 'rsslim', 'startcode', 'endcode',
                 'startstack', 'kstkesp', 'kstkeip', 'signal', 'blocked',
                 'sigignore', 'sigcatch', 'wchan', 'nswap', 'cnswap',
                 'exit_signal', 'processor', 'rt_priority', 'policy',
                 'delayacct_blkio_ticks', 'guest_time', 'cguest_time',
                 'start_data', 'end_data', 'start_brk', 'arg_start',
                 'arg_end', 'env_start', 'env_end', 'exit_code')
    with open(_proc_stat) as fd:
        v = fd.read()
    _idx = v.rfind(')') + 2  # ignore "pid (comm)"
    _v = v[_idx:].split()
    return dict(zip(PROC_STAT, _v))


def _get_pid(proc_name):
    pids = None
    try:
        pids = map(int, check_output(["pidof", proc_name]).split())
    except:  # no program was found with the requested name.
        pids = []
    return pids


def send_mail(**kwargs):
    proc_name = kwargs.get('proc_name')
    hostname = socket.getfqdn()
    subject = u'[{0} 重启] {1}'.format(proc_name, hostname)
    fromaddr = 'root@{0}'.format(hostname)
    toaddr = ('ops@intra.knownsec.com',)
    rss_mem_usage = kwargs.get('rss_mem_usage')
    threshold = kwargs.get('threshold')
    content = (u'{0} 内存使用{1}MB, '
               u'超过阈值{2}MB, '
               u'自动重启提醒(watch_{0}.py)'
               .format(proc_name, rss_mem_usage/1024.0/1024,
                       threshold/1024.0/1024))
    _send_mail(fromaddr, toaddr, subject, content, priority=1)


def restart_service(proc_name):
    cmd = ['service', proc_name, 'restart']
    exec_cmd(cmd)


def main(**kwargs):
    proc_name = kwargs.get('proc_name')
    threshold = kwargs.get('threshold')
    sleep_time = kwargs.get('sleep_time')
    while True:
        try:
            pids = _get_pid(proc_name)
            for pid in pids:
                mem_info = mem_info_of_pid(pid)
                ppid = int(mem_info['ppid'])
                if ppid != 1:  # check if parent process ?
                    continue
                rss_mem_usage = int(mem_info['rss']) * PAGE_SIZE
                if rss_mem_usage > threshold:
                    try:
                        send_mail(proc_name=proc_name,
                                  rss_mem_usage=rss_mem_usage,
                                  threshold=threshold)
                    except Exception as e:
                        logger.critical(traceback.format_exc())
                    restart_service(proc_name)
        except Exception as e:
            logger.critical(traceback.format_exc())
        time.sleep(sleep_time)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='watch process memory usage')
    parser.add_argument('--proc', dest='proc_name', required=True,
                        help='process name')
    parser.add_argument('--threshold', dest='threshold', type=float,
                        default=1.0, help='memory threshold, in GB')
    parser.add_argument('--sleep', dest='sleep_time', type=int, default=60,
                        help='sleep time after next check, in seconds')

    args = parser.parse_args()
    _kwargs = {}
    _kwargs['proc_name'] = args.proc_name
    _kwargs['sleep_time'] = args.sleep_time
    _kwargs['threshold'] = args.threshold * 1024 * 1024 * 1024.0  # in Bytes

    logger = ops_log_open(level=logging.INFO,
                          syslog={'ident': "watch_{0}"
                                           .format(_kwargs['proc_name']),
                                  'level': logging.INFO})

    main(**_kwargs)
