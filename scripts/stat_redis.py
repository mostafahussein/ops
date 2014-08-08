#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Ref: http://redis.io/commands/INFO
from pprint import pprint
import redis

keys = {
    "server": (
        # Number of seconds since Redis server start
        "uptime_in_seconds",
    ),
    "client": (
        # Number of client connections (excluding connections from slaves)
        "connected_clients",
        # Number of clients pending on a blocking call (BLPOP, BRPOP,
        # BRPOPLPUSH)
        "blocked_clients",
    ),
    "memory": (
        # Total number of bytes allocated by Redis using its allocator
        "used_memory",
        # Number of bytes that Redis allocated as seen by the operating
        # system (a.k.a resident set size).
        # This is the number reported by tools such as top and ps.
        "used_memory_rss",
        # Peak memory consumed by Redis (in bytes)
        "used_memory_peak",
        # Number of bytes used by the Lua engine
        "used_memory_lua",
    ),
    "persistence": (
        # Number of changes since the last dump
        "rdb_changes_since_last_save",
        # Epoch-based timestamp of last successful RDB save
        "rdb_last_save_time",
        # AOF current file size
        "aof_current_size",
        # AOF file size on latest startup or rewrite
        "aof_base_size",
    ),
    "stats": (
        # Total number of connections accepted by the server
        "total_connections_received",
        # Total number of commands processed by the server
        "total_commands_processed",
        # Number of connections rejected because of maxclients limit
        "rejected_connections",
        # Total number of key expiration events
        "expired_keys",
        # Number of evicted keys due to maxmemory limit
        "evicted_keys",
        # Number of successful lookup of keys in the main dictionary
        "keyspace_hits",
        # Number of failed lookup of keys in the main dictionary
        "keyspace_misses",
        # Global number of pub/sub channels with client subscriptions
        "pubsub_channels",
        # Global number of pub/sub pattern with client subscriptions
        "pubsub_patterns",
    ),
    "replication": (
        "role",
        # Number of connected slaves
        "connected_slaves",
    ),
    "cpu": (
        # System CPU consumed by the Redis server
        "used_cpu_sys",
        # User CPU consumed by the Redis server
        "used_cpu_user",
        # System CPU consumed by the background processes
        "used_cpu_sys_children",
        # User CPU consumed by the background processes
        "used_cpu_user_children",
    ),
    "keyspace": (
        # the number of keys, and the number of keys with an expiration
        "db0",
        "db1",
    )
}


def format_redis_info(redis_info):
    """Get redis all info by type formate"""
    data = {}
    role_map = {'master': 1, 'slave': 0}
    for _type in keys:
        if _type not in data:
            data[_type] = {}
        for k in keys[_type]:
            if k in redis_info:
                if k == "role":
                    data[_type][k] = role_map[redis_info[k]]
                else:
                    data[_type][k] = redis_info[k]
    return data


def stat_redis(**kwargs):
    r = redis.Redis(**kwargs)
    try:
        redis_info = r.info("all")
    except TypeError:
        redis_info = r.info()
    return format_redis_info(redis_info)


if __name__ == "__main__":
    login_kwargs = {"unix_socket_path": "/tmp/redis_sites.sock"}
    pprint(stat_redis(**login_kwargs))
