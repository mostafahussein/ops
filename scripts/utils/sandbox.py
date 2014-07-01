#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import yaml
import traceback

from os import path as osp


def setup():

    libsandbox = {
        'x86_64': '/usr/lib64/libsandbox.so',
    }

    machine = os.uname()[-1]
    libsandbox = libsandbox.get(machine)

    if not osp.exists(libsandbox):
        return False

    os.environ['LD_PRELOAD'] = libsandbox
    os.environ['SANDBOX_ON'] = "1"
    os.environ['SANDBOX_LOG'] = "/tmp/sandbox.log"
    os.environ['SANDBOX_READ'] = "/"
    os.environ['SANDBOX_ACTIVE'] = "armedandready"


def enable(dir):
    os.environ['SANDBOX_WRITE'] = dir


def disable():
    if 'SANDBOX_WRITE' in os.environ:
        os.environ.pop('SANDBOX_WRITE')


if __name__ == "__main__":
    sandbox_setup()
    sandbox_enable('/home')
    sandbox_disable()
