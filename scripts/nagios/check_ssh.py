#!/usr/bin/env python
# -*- coding: utf-8 -*-
# pylint: disable=redefined-outer-name
import sys
from os import path as osp

base_dir = osp.dirname(osp.dirname(osp.realpath(__file__)))
if base_dir not in sys.path:
    sys.path.insert(0, base_dir)

from utils import ssh
from utils import nagios


def check_ssh(host, ssh_version, auths, port=22, timeout=30):
    """Check SSH service protocol version, opened authentication type."""
    conn = None  # predefine conn for close socket
    try:
        # validate ssh version
        if ssh_version not in ('1', '1.99', '2'):
            return (nagios.STATE_UNKNOWN,
                    "SSH version should be 1, 1.99 or 2")

        # validate auth type
        # @todo: GSSAPI and Kerberos not include
        valid_auth_type = ['publickey', 'keyboard-interactive', 'hostbased',
                           'password']
        if auths:
            if not all((_ in valid_auth_type for _ in auths)):
                return (nagios.STATE_UNKNOWN,
                        "Auth type should in '{0}'"
                        .format(','.join(valid_auth_type)))

        _msg = []
        ret = nagios.STATE_OK

        if ssh_version:
            conn = ssh.do_connect(host, port, timeout)
            banner = ssh.get_ssh_banner(conn)
            _version = ssh.get_ssh_version(banner)
            if ssh_version != _version:
                ret = nagios.STATE_WARNING
                _msg.append("Version: expected {0} but `{1}'" \
                            .format(ssh_version, _version))
            else:
                _msg.append('Version: {0}'.format(banner))

        if auths:
            _auths = ssh.get_ssh_auth(host, port)
            unexpected_auths = [a for a in _auths if a not in auths]
            if unexpected_auths:
                ret = nagios.STATE_CRITICAL
                _msg.append("Auth: expected {0} but `{1}'" \
                            .format(','.join(auths), ','.join(_auths)))
            else:
                _msg.append('Auth: {0}'.format(','.join(_auths)))

        msg = ','.join(_msg)
        return (ret, msg)
    except Exception as e:
        return (nagios.STATE_UNKNOWN, str(e))
    finally:
        if conn:
            conn.close()


if __name__ == '__main__':
    # pylint: disable=superfluous-parens
    import argparse
    parser = argparse.ArgumentParser(description='Try to connect to an '
                                     'SSH server at specified server and port')
    parser.add_argument('-H', '--hostname', dest='hostname',
                        required=True, help='Host name, IP Address')
    parser.add_argument('-p', '--port', dest='port',
                        default=22, type=int, help='Port number (default: 22)')
    parser.add_argument('-t', '--timeout', dest='timeout', default='10',
                        help='Seconds before connection time out (default: 10)')
    parser.add_argument('-V', '--ssh-version', dest='ssh_version', default='2',
                        help="check ssh version (1/1.99/2, default is 2)")
    parser.add_argument('-a', '--auth', dest='auth', nargs='+',
                        help='Check he authentication type '
                        '(publickey/password/hostbased/keyboard-interactive)')
    args = parser.parse_args()

    hostname = args.hostname
    port = args.port
    ssh_version = args.ssh_version
    auths = args.auth
    rtcode, msg = check_ssh(host=hostname, port=port, ssh_version=ssh_version,
                            auths=auths)
    print(msg)
    sys.exit(rtcode)
