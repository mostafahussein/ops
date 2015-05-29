#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys
import shlex
import socket

from . import exec_cmd


def count_mail_queue(mail_type):
    '''return (mail_num, ret_code, msg)

    if `ret_code` not 0, run command error;
    if `mail_num` not 0, have blocked mails in queue.
    '''
    _func = getattr(sys.modules[__name__], 'count_{0}_queue'.format(mail_type))
    return _func()


def count_exim_queue():
    mail_num = ret_code = msg = None

    ret_code, msg = exec_cmd(shlex.split('exim -bpc'))
    msg = msg.strip()

    if ret_code is None:
        ret_code = -1

    if not ret_code:
        try:
            mail_num = int(msg)
        except:
            ret_code = -1

    return (mail_num, ret_code, msg)


def get_mail_banner(host='127.0.0.1', port=25):
    '''first received data after socket connected

    TODO: socket connect can be in util function, with utils/ssh.py
    '''
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((host, port))
    banner = sock.recv(1024).strip()
    sock.close()
    return banner
