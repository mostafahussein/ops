#!/usr/bin/python
# -*- coding: UTF-8 -*-

# @todo get call arg from config, [-j|-x]

import json
import subprocess
import traceback

from utils import exec_cmd as exec_cmd

VARNISH_FIELD = [
    #"client_conn",                # Client connections accepted
    #"client_drop",                # Connection dropped, no sess/wrk
    #"client_req",                 # Client requests received
    #"cache_hit",                  # Cache hits
    #"cache_hitpass",              # Cache hits for pass
    #"cache_miss",                 # Cache misses
    #"backend_conn",               # Backend conn. success
    #"backend_unhealthy",          # Backend conn. not attempted
    #"backend_busy",               # Backend conn. too many
    #"backend_fail",               # Backend conn. failures
    #"backend_reuse",              # Backend conn. reuses
    #"backend_toolate",            # Backend conn. was closed
    #"backend_recycle",            # Backend conn. recycles
    #"backend_retry",              # Backend conn. retry
    #"fetch_head",                 # Fetch head
    #"fetch_length",               # Fetch with Length
    #"fetch_chunked",              # Fetch chunked
    #"fetch_eof",                  # Fetch EOF
    #"fetch_bad",                  # Fetch had bad headers
    #"fetch_close",                # Fetch wanted close
    #"fetch_oldhttp",              # Fetch pre HTTP/1.1 closed
    #"fetch_zero",                 # Fetch zero len
    #"fetch_failed",               # Fetch failed
    #"fetch_1xx",                  # Fetch no body (1xx)
    #"fetch_204",                  # Fetch no body (204)
    #"fetch_304",                  # Fetch no body (304)
    #"n_sess_mem",                 # N struct sess_mem
    "n_sess",                     # N struct sess
    #"n_object",                   # N struct object
    #"n_vampireobject",            # N unresurrected objects
    #"n_objectcore",               # N struct objectcore
    #"n_objecthead",               # N struct objecthead
    #"n_waitinglist",              # N struct waitinglist
    #"n_vbc",                      # N struct vbc
    "n_wrk",                      # N worker threads
    #"n_wrk_create",               # N worker threads created
    #"n_wrk_failed",               # N worker threads not created
    #"n_wrk_max",                  # N worker threads limited
    #"n_wrk_lqueue",               # work request queue length
    #"n_wrk_queued",               # N queued work requests
    #"n_wrk_drop",                 # N dropped work requests
    #"n_backend",                  # N backends
    #"n_expired",                  # N expired objects
    #"n_lru_nuked",                # N LRU nuked objects
    #"n_lru_moved",                # N LRU moved objects
    #"losthdr",                    # HTTP header overflows
    #"n_objsendfile",              # Objects sent with sendfile
    #"n_objwrite",                 # Objects sent with write
    #"n_objoverflow",              # Objects overflowing workspace
    #"s_sess",                     # Total Sessions
    #"s_req",                      # Total Requests
    #"s_pipe",                     # Total pipe
    #"s_pass",                     # Total pass
    #"s_fetch",                    # Total fetch
    #"s_hdrbytes",                 # Total header bytes
    #"s_bodybytes",                # Total body bytes
    #"sess_closed",                # Session Closed
    #"sess_pipeline",              # Session Pipeline
    #"sess_readahead",             # Session Read Ahead
    #"sess_linger",                # Session Linger
    #"sess_herd",                  # Session herd
    #"shm_records",                # SHM records
    #"shm_writes",                 # SHM writes
    #"shm_flushes",                # SHM flushes due to overflow
    #"shm_cont",                   # SHM MTX contention
    #"shm_cycles",                 # SHM cycles through buffer
    #"sms_nreq",                   # SMS allocator requests
    #"sms_nobj",                   # SMS outstanding allocations
    #"sms_nbytes",                 # SMS outstanding bytes
    #"sms_balloc",                 # SMS bytes allocated
    #"sms_bfree",                  # SMS bytes freed
    #"backend_req",                # Backend requests made
    #"n_vcl",                      # N vcl total
    #"n_vcl_avail",                # N vcl available
    #"n_vcl_discard",              # N vcl discarded
    #"n_ban",                      # N total active bans
    #"n_ban_gone",                 # N total gone bans
    #"n_ban_add",                  # N new bans added
    #"n_ban_retire",               # N old bans deleted
    #"n_ban_obj_test",             # N objects tested
    #"n_ban_re_test",              # N regexps tested against
    #"n_ban_dups",                 # N duplicate bans removed
    #"hcb_nolock",                 # HCB Lookups without lock
    #"hcb_lock",                   # HCB Lookups with lock
    #"hcb_insert",                 # HCB Inserts
    #"esi_errors",                 # ESI parse errors (unlock)
    #"esi_warnings",               # ESI parse warnings (unlock)
    #"accept_fail",                # Accept failures
    #"client_drop_late",           # Connection dropped late
    "uptime",                     # Client uptime
    #"dir_dns_lookups",            # DNS director lookups
    #"dir_dns_failed",             # DNS director failed lookups
    #"dir_dns_hit",                # DNS director cached lookups hit
    #"dir_dns_cache_full",         # DNS director full dnscache
    #"vmods",                      # Loaded VMODs
    #"n_gzip",                     # Gzip operations
    #"n_gunzip",                   # Gunzip operations
]

# @todo check -j option is supported
VARNISHSTAT = ("varnishstat", "-1", "-j", "-f", ','.join(VARNISH_FIELD))


def stat_varnish(**kwargs):
    ret, vstat = exec_cmd(VARNISHSTAT)
    vstats = json.loads(vstat)
    for k, v in vstats.items():
        if k == 'timestamp':
            vstats.pop(k)
        else:
            if isinstance(v, dict):
                value = v.get('value')
            if value is not None:
                vstats[k] = value
    if 'n_wrk' in vstats and 'n_sess' in vstats:
        vstats['n_wrk_idle'] = vstats['n_wrk'] - vstats['n_sess']
        vstats.pop('n_sess')

    return vstats


if __name__ == "__main__":
    print stat_varnish()
