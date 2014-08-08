#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import os
import sys
import time
import json
import zlib
import traceback
from pprint import pprint


# cpu idle/wait/user/system
# stat context/interrupt
def stat_info():
    try:
        stats = {}
        lines = open('/proc/stat').readlines()
        for line in lines:
            les = line.split()
            key = les[0]
            if key.startswith('cpu'):
                # @todo split le[1:]
                if key == 'cpu':
                    stats[key] = {}
                    stats[key]['count'] = 0
                    stats[key]['stat'] = {}
                    cpu_usage = tuple(map(int, les[1:]))
                    len_usage = len(cpu_usage)
                    stats[key]['stat']['sys'] = cpu_usage[2]
                    stats[key]['stat']['user'] = cpu_usage[0]
                    stats[key]['stat']['nice'] = cpu_usage[1]
                    stats[key]['stat']['idle'] = cpu_usage[3]
                    if len_usage > 4:
                        stats[key]['stat']['irq'] = cpu_usage[5]
                        stats[key]['stat']['iowait'] = cpu_usage[4]
                        stats[key]['stat']['softirq'] = cpu_usage[6]
                    if len_usage > 7:
                        stats[key]['stat']['steal'] = cpu_usage[7]
                        stats[key]['stat']['guest'] = cpu_usage[8]
                        stats[key]['stat']['guestnice'] = cpu_usage[8]
                else:
                    idx = int(key[3:])
                    stats['cpu']['count'] = stats['cpu']['count'] + 1
            elif key in ('intr', 'softirq'):
                stats[key] = sum([int(x) for x in les[1:]])
            elif key in ('ctxt', 'processes',
                         'procs_running', 'procs_blocked'):
                stats[key] = int(les[1])
            else:
                continue
        return stats
    except:
        raise


# swapin/swapout
# io sent/received
def vmstat_info():
    conv_table = {
        'pgpgin': 'ioread',
        'pgpgout': 'iowrite',
    }

    try:
        stats = {}
        lines = open('/proc/vmstat').readlines()
        for line in lines:
            (k, v) = line.split()
            if k not in ('pswpin', 'pswpout', 'pgpgin', 'pgpgout'):
                continue
            k = conv_table.get(k, k)
            v = int(v)
            if k in ('ioread', 'iowrite'):   # disk block size is 512
                v = v * 2
            stats[k] = int(v)
        return stats
    except:
        raise


# todo
def diskstat_info():
    try:
        stats = {}
        lines = open('/proc/diskstats').readlines()
        for line in lines:
            les = line.split()
            if len(les) != 14:
                pass
            else:
                pass
        return stats
    except:
        raise


# load 1/5/15
def load_info():
    try:
        content = open('/proc/loadavg').read().split()
        (nr_running, nr_threads) = content[3].split('/')
        la = tuple(map(float, content[0:3]))
        return {
            'load': {
                '1': la[0],
                '5': la[1],
                '15': la[2],
            },
            'proc': int(nr_threads),
        }
    except:
        raise


# mem total/free/buffer/cache
# swap total/free
def mem_info():
    try:
        unit = 1   # kB
        mem = {}
        content = open('/proc/meminfo').readlines()
        for line in content:
            # no unit for HugePages_Total, ...
            les = line.split()
            (k, v) = (les[0], les[1])
            if not k.endswith(':'):
                raise ':'
                continue
            k = k[:-1]
            if k not in ('MemTotal', 'MemFree', 'Buffers',
                         'Cached', 'SwapTotal', 'SwapFree'):
                continue
            u = les[2]
            if u != 'kB':
                raise 'kB'
                continue
            mem[k] = int(v) * unit
        return mem
    except:
        raise


# uptime
def uptime_info():
    try:
        (uptime, idle) = open('/proc/uptime').read().split()
        return float(uptime)
    except:
        raise


# proc process


# tcp, udp
# @todo icmp, ip, snmp
def net_snmp_info():
    key_ignored = {
        'tcp': ('RtoAlgorithm', 'RtoMin', 'RtoMax', 'MaxConn', 'InCsumErrors'),
        'udp': ('RcvbufErrors', 'SndbufErrors', 'InCsumErrors'),
    }

    conv_table = {
        'InSegs': 'inseg',
        'InErrs': 'inerr',
        'NoPorts': 'noport',
        'OutSegs': 'outseg',
        'OutRsts': 'outrst',
        'InErrors': 'inerr',
        'CurrEstab': 'current',
        'RetransSegs': 'reseg',
        'ActiveOpens': 'aopen',
        'EstabResets': 'estrst',
        'InDatagrams': 'inpkt',
        'PassiveOpens': 'popen',
        'AttemptFails': 'fattemp',
        'OutDatagrams': 'outpkt',
    }

    try:
        net = {}
        keys = {}
        values = {}
        lines = open('/proc/net/snmp').readlines()
        for line in lines:
            les = line.split()
            key = les[0].rstrip(':').lower()
            if keys.get(key):
                if values.get(key):
                    raise 'key'
                values[key] = tuple(map(int, les[1:]))
                net[key] = dict(zip(keys[key], values[key]))
            else:
                keys[key] = les[1:]
        for key in net.keys():
            ignored_keys = key_ignored.get(key)
            if not ignored_keys:
                net.pop(key)
                continue
            _net = {}
            for k, v in net[key].items():
                _net[conv_table.get(k, k)] = v
            net[key] = _net
            for k in ignored_keys:
                if k in net.get(key, ()):
                    net[key].pop(k)
            if not net[key].keys():
                net.pop(key)
        return net
    except:
        raise


# net in/out
def net_info():
    try:
        net = {}
        lines = open('/proc/net/dev').readlines()
        for line in lines[2:]:
            con = line.split(':')
            nic = con[0].strip(': ')
            if nic in net:
                raise 'duplicated nic'
            if nic == 'lo':
                continue
            intf = dict(zip(
                ('in', 'inpkt', 'inerr', 'indrop',
                 'infifo', 'inframe', 'incompressed', 'inmulticast',
                 'out', 'outpkt', 'outerr', 'outdrop',
                 'outfifo', 'outframe', 'outcompressed', 'outmulticast'),
                tuple(map(int, con[1].split())))
            )
            for k in intf.keys():
                if k not in ('in', 'inpkt', 'out', 'outpkt'):
                    intf.pop(k)
            net[nic] = intf
        return net
    except:
        raise


# disk inode/unit/total/used
def disk_info():
    DYNAMIC_FSS = ('afs', 'anon_inodefs', 'auto', 'autofs', 'bdev', 'binfmt',
                   'binfmt_misc', 'cgroup', 'cifs', 'coda', 'configfs',
                   'cramfs', 'cpuset', 'debugfs', 'devpts', 'devtmpfs',
                   'devfs', 'devpts', 'ecryptfs', 'eventpollfs', 'exofs',
                   'futexfs', 'ftpfs', 'fuse', 'fusectl', 'gfs', 'gfs2',
                   'hostfs', 'hugetlbfs', 'inotifyfs', 'iso9660', 'jffs2',
                   'lustre', 'misc', 'mqueue', 'ncpfs', 'nfs', 'NFS', 'nfs4',
                   'nfsd', 'nnpfs', 'ocfs', 'ocfs2', 'pipefs', 'proc',
                   'ramfs', 'rootfs', 'rpc_pipefs', 'securityfs', 'selinuxfs',
                   'sfs', 'shfs', 'smbfs', 'sockfs', 'spufs', 'sshfs',
                   'subfs', 'supermount', 'sysfs', 'tmpfs', 'ubifs', 'udf',
                   'usbfs', 'vboxsf', 'vperfctrfs')

    DYNAMIC_PATHS = ('/proc/', '/sys/', '/run/', '/dev/', '/mnt/')

    DYNAMIC_MOPTS = ('bind',)

    try:
        hd = {}
        mounts = open('/proc/mounts').readlines()
        for m in mounts:
            me = m.split()
            fs = me[2]
            if fs in DYNAMIC_FSS:
                continue
            mnt = me[1]
            if filter(lambda p: mnt.startswith(p), DYNAMIC_PATHS):
                continue
            mopts = me[3]
            usage = {}
            st_dev = os.stat(mnt).st_dev
            if hd.keys():
                if filter(lambda k: hd[k]['dev'] == st_dev, hd.keys()):
                    continue
            dsk = os.statvfs(mnt)
            usage['dev'] = st_dev
            usage['unit'] = dsk.f_bsize
            usage['used'] = dsk.f_blocks - dsk.f_bfree
            usage['total'] = dsk.f_blocks
            #usage['itotal'] = dsk.f_files
            #usage['iused']  = usage['itotal'] - dsk.f_ffree
            if dsk.f_files != 0:
                usage['inode'] = 100 - 100 * dsk.f_ffree / dsk.f_files
            hd[mnt] = usage
        for k, v in hd.items():
            v.pop('dev')
        return hd
    except:
        raise


def sysstat():
    stats = {
        'proc': {},
        'sysstat': {},
    }
    stats['uptime'] = uptime_info()
    _load = load_info()
    stats['load'] = _load['load']
    stats['proc']['count'] = _load['proc']
    #stats['proc.count'] = load['proc']
    stats['mem'] = mem_info()

    stat = stat_info()
    stats['cpu'] = stat.get('cpu')
    stats['proc']['fork'] = stat['processes']
    stats['proc']['running'] = stat['procs_running']
    stats['sysstat']['ctxt'] = stat['ctxt']
    stats['sysstat']['intr'] = stat['intr']
    stats['sysstat']['softirq'] = stat['softirq']

    stats['vmstat'] = vmstat_info()
    stats['net_stat'] = net_snmp_info()
    stats['time'] = int(time.time())

    stats['net'] = net_info()
    stats['disk'] = disk_info()
    return stats


def flat_dict(stats, new, prefix):
    for k in new.keys():
        key = ".".join([prefix, k])
        if isinstance(new[k], dict):
            flat_dict(stats, new[k], key)
        else:
            stats[key] = new[k]


def normalize_stat(stats):
    for k in ("cpu", "load", "mem", "net_stat", "proc", "sysstat", "vmstat"):
        flat_dict(stats, stats.get(k), k)
        stats.pop(k)


if __name__ == '__main__':
    stats = sysstat()
    print json.dumps(stats, sort_keys=True, indent=4)
    print len(json.dumps(stats)), len(zlib.compress(json.dumps(stats)))
    normalize_stat(stats)
    #print json.dumps(stats, sort_keys = True, indent = 4)
