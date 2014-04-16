#!/usr/bin/gawk -f

#2014-04-14T15:11:10.948774+08:00 gw-sanxin2(fd6d:523c:4aff:a:3::fe) daemon.notice vpn-server.sanxin[9142]:  180.76.4.59:2125 TLS: Initial packet from [AF_INET]180.76.4.59:2125 (via [AF_INET]118.192.48.5%eth1), sid=23963e99 32abef1d
#2014-04-14T15:01:25.190468+08:00 gw-sanxin2(fd6d:523c:4aff:a:3::fe) daemon.notice vpn-server.sanxin[9142]:  180.76.4.63:2132 CRL CHECK FAILED: C=CN, O=Knownsec, OU=JiaSuLe, CN=jsl-cdn-baidu-hk4, emailAddress=jiasule@knownsec.com is REVOKED
#2014-04-14T14:02:53.332974+08:00 gw-sanxin2(fd6d:523c:4aff:a:3::fe) daemon.notice vpn-server.sanxin[9142]:  222.171.13.130:19749 [linf] Peer Connection Initiated with [AF_INET]222.171.13.130:19749 (via [AF_INET]118.192.48.5%eth1)
BEGIN {
}

{
    if ($4 !~ /vpn-server./) {
        next
    }

    if ($6 == "CRL" && $7 == "CHECK" && $8 == "FAILED:") {
        crl = substr($12, 4, length($12) - 1 - 3)
        if (crl in crls) {
            crls[crl] += 1
        } else {
            crls[crl] = 1
        }
    } else if ($6 == "TLS:" && $7 == "Initial") {
        split(substr($10, 10), a, ":")
        init = a[1]
        if (init in inits) {
            inits[init] += 1
        } else {
            inits[init] = 1
        }
    } else if ($7 == "Peer" && $8 == "Connection" && $9 == "Initiated") {
        user=substr($6, 2, length($6) -2)
        if (user in users) {
            users[user] += 1
        } else {
            users[user] = 1
        }
    }
    next
    user = substr($5, 2, length($5) -2)
    #if (user ~ /jsl-/) next
    #if (user ~ /office-/) next
    #if (user ~ /idc-/) next
    if (user in users) {
        users[user] += 1
    } else {
        users[user] = 1
    }
}

END {
    print "==> Connection attempt"
    for (u in inits) {
        print inits[u], u
    }
    print "==> Connection w/ revoked cert"
    for (u in crls) {
        print crls[u], u
    }
    print "==> User connec statistic"
    for (u in users) {
        print users[u], u
    }
}
