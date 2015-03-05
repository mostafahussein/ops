#!/usr/bin/env python
# -*- coding: utf-8 -*-
import socket
import re
import shlex

from . import exec_cmd


def do_connect(host, port, timeout=None, proto=None):
    '''try to connect host:port and return connection socket

    proto indicate ipv4, ipv6 or any, valid value in ('4', '6', None)
    '''
    if proto not in ('4', '6', None):
        raise Exception("`proto' should in ('4', '6', None')")
    family_d = {'4': socket.AF_INET, '6': socket.AF_INET6}
    family = family_d.get(proto, socket.AF_UNSPEC)
    if timeout:
        socket.setdefaulttimeout(timeout)
    addrinfos = socket.getaddrinfo(host, port, family, socket.SOCK_STREAM)

    for addrinfo in addrinfos:
        family, socktype, proto, canonname, sockaddr = addrinfo  # pylint: disable=unused-variable
        try:
            # note ipv6 will before ipv4 if not sort
            conn = socket.socket(family, socktype, proto)
            conn.connect(sockaddr)
            break
        except socket.error:
            conn.close()
            raise
    return conn


def get_ssh_banner(conn):
    '''see RFC4253
    for SSH 2.0, the identification string is
      SSH-2.0-*<CR><LF>

    In the compatibility mode, the identification string is
      SSH-1.99-*<LF>

    for ealier version, the identification string is
      SSH-1.x-*<LF>
    '''
    conn.sendall('SSH-2.0-check-ssh\r\n')
    ssh_banner = conn.recv(1024).strip()
    return ssh_banner


def get_ssh_auth(host, port):
    cmd = 'ssh -l root -o PreferredAuthentications=none \
           -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null -p {0} {1}'.format(port, host)
    cmd = shlex.split(cmd)
    ret, out = exec_cmd(cmd)
    out = out.strip()
    result = re.search('Permission denied \((?P<auth>.+)\)', out)  # pylint: disable=anomalous-backslash-in-string
    if not result:
        raise Exception("Can't find auth type in: {0}".format(out))
    auth = result.group('auth').split(',')
    return auth


def get_ssh_version(banner):
    '''get the ssh version by parsing version message'''
    version = banner.split('-')[1]
    if version == '1.99':
        version = '1.99'
    elif version.startswith('1.'):
        version = '1'
    elif version.startswith('2.'):
        version = '2'
    else:
        raise Exception('Unknown version: {0}'.format(banner))

    return version


def get_ssh_info(host, port=22, timeout=None):
    '''if ssh running, get the ssh banner(version) message, and
    opened auth type.'''
    ssh_info = {}
    conn = None  # predefine conn for close socket
    try:
        # get ssh version info by socket
        conn = do_connect(host, port, timeout)
        ssh_info['banner'] = get_ssh_banner(conn)
        ssh_info['version'] = get_ssh_version(ssh_info['banner'])

        # get ssh opened auth type
        ssh_info['auth'] = get_ssh_auth(host, port)
        return ssh_info
    finally:
        if conn:
            conn.close()
