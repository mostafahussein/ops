#!/bin/bash

md5sum  /etc/salt/pki/master/*/* | sort | awk '
{
    md5=$1
    file=$2
    if (md5 in md5s) {
        md5s[md5][length(md5s[md5])] = file
    } else {
        md5s[md5][0] = file
    }
}

END {
    for (m in md5s) {
        if (length(md5s[m]) > 1) {
			print m
			for (i=0; i<length(md5s[m]); i++) {
				print "  ", md5s[m][i]
			}
        }
    }
}
'
