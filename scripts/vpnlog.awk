#!/usr/bin/gawk -f

#2014-04-14T15:11:10.948774+08:00 gw-x(fd6d::) daemon.notice vpn-server.xxx[9142]:  1.2.3.4:5 TLS: Initial packet from [AF_INET]180.76.4.59:2125 (via [AF_INET]x.x.x.x%eth1), sid=23963e99 32abef1d
#2014-04-14T15:01:25.190468+08:00 gw-x(fd6d::) daemon.notice vpn-server.xxx[9142]:  1.2.3.4:5 CRL CHECK FAILED: C=CN, O=X, OU=X, CN=x, emailAddress=x@x.com is REVOKED
#2014-04-14T14:02:53.332974+08:00 gw-x(fd6d::) daemon.notice vpn-server.xxx[9142]:  1.2.3.4:5 [xxx] Peer Connection Initiated with [AF_INET]1.2.3.4:5 (via [AF_INET]x.x.x.x%eth1)
#2015-04-08T08:11:34.221335+08:00 gw-x(fd6d::) daemon.notice vpn-server.xxx[8721]:  117.79.232.219:8055 SENT CONTROL [linf]: 'AUTH_FAILED' (status=1)
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
    } else if ($6 == "SENT" && $7 == "CONTROL" && $9 == "'AUTH_FAILED'") {
        fuser = substr($8, 2, length($8) -3)
        if (fuser in fusers) {
            fusers[fuser] += 1
        } else {
            fusers[fuser] = 1
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
    print ">>> Connection w/ revoked cert"
    for (u in crls) {
        printf "%5d %s\n", crls[u], u
    }
    print ">>> AUTH Failed user statistic"
    for (u in fusers) {
        printf "%5d %s\n", fusers[u], u
    }
    print ">>> User connect statistic"
    for (u in users) {
        printf "%5d %s\n", users[u], u
    }
    print ">>> Connection attempt"
    for (u in inits) {
        printf "%5d %s\n", inits[u], u
    }
}
