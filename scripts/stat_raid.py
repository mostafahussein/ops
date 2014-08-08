#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
from utils import exec_cmd


def stat_raid(**kwargs):
    raid_status = {}

    try:
        cmd = "megacli -LDInfo -Lall -aALL -NoLog"
        ret, ld_info = exec_cmd(cmd)
        ld_status = re.findall('state\s+:\s(.+)', ld_info, re.I)
    except Exception, e:
        ld_status = str(e)

    raid_status["ld"] = ld_status

    return raid_status


if __name__ == "__main__":
    print stat_raid()
