#!/usr/bin/python
# -*- coding: UTF-8 -*-
import netsnmp

class snmp(object):
    '''use bulkget instead of walk'''
    def __init__(self, **kwargs):
        dest = kwargs.get('dest')
        if not dest:
            raise RuntimeError('snmp() destination must provided')
        version = kwargs.get('version', 2)
        community = kwargs.get('community', 'public')
        timeout = kwargs.get('timeout', 500000)
        retries = kwargs.get('retries', 3)
        self.sess = netsnmp.Session(Version=version,
                                    DestHost=dest,
                                    Community=community,
                                    Timeout=timeout,
                                    Retries=retries)

    def get(self, oids):
        varbinds = netsnmp.VarList()
        for oid in oids:
            varbinds.append(netsnmp.Varbind(oid))
        results = self.sess.get(varbinds)
        # if get None, netsnmp will return ('',)
        if not results[0]:
            raise Exception('Snmp get return None')
        return results

    def walk(self, oids):
        #  XXX Note that only one varbind should be contained in the
        #  VarList passed in.  The code is structured to maybe
        #  handle this is the the future, but right now walking
        #  multiple trees at once is not yet supported and will
        #  produce insufficient results.
        varbinds = netsnmp.VarList()
        for oid in oids:
            varbinds.append(netsnmp.Varbind(oid))
        self.sess.walk(varbinds)
        # note if no varbind walk(such as oid error), will still return
        # a varbind object with iid zero
        if not varbinds[0].iid:
            raise Exception('Snmp walk return None')
        return varbinds

    @staticmethod
    def _bulk_test(oids, varbinds):
        '''if varbinds contain specify oid, continue get next bulk;
        else get is done'''
        iids = [None] * len(oids)
        done = [False] * len(oids)
        for pos, oid in enumerate(oids):
            vs = [v for v in varbinds if v.tag == oid]
            if len(vs) == 0:
                done[pos] = True
            else:
                iids[pos] = int(vs[-1].iid)
        return (done, iids)

    def bulkget(self, oids, nonrepeaters=0, maxrepetitions=10):
        '''improved of walk, return varbind type list'''
        # pylint: disable=too-many-locals
        results = []
        iids = [None] * len(oids)
        done = [False] * len(oids)
        while True:
            finished = True
            for d in done:
                if not d:
                    finished = False
                    break
            if finished:
                break
            varbinds = netsnmp.VarList()
            for pos, oid in enumerate(oids):
                if done[pos]:
                    continue
                iid = iids[pos]
                if iid:
                    varbinds.append(netsnmp.Varbind(oid, iid))
                else:
                    varbinds.append(netsnmp.Varbind(oid))
            res = self.sess.getbulk(nonrepeaters, maxrepetitions, varbinds)
            if not res:
                raise Exception('Snmp bulkget return None')
            (done, iids) = snmp._bulk_test(oids, varbinds)

            results.extend([v for v in varbinds if v.tag in oids])

        rets = []
        for v in results:
            same_oid_with_v = [r for r in rets if r.tag == v.tag]
            if [r for r in same_oid_with_v if r.iid == v.iid]:
                continue
            rets.append(v)
        return rets

if __name__ == "__main__":
    # pylint: disable=broad-except
    import sys
    if len(sys.argv) == 3:
        _dest = sys.argv[1]
        _community = sys.argv[2]
    else:
        sys.exit("Usage: ./snmp.py <dest> <community>")
    try:
        t_sess = snmp(dest=_dest, community=_community)
        t_sess.get(('sysContact.0',))
        t_sess.walk(('system',))
        t_oids = ('ifName', 'ifHCInOctets', 'ifHCInUcastPkts',
                  'ifHCOutOctets', 'ifHCOutUcastPkts')
        for t_v in t_sess.bulkget(t_oids, maxrepetitions=10):
            print "{} {} {}".format(t_v.tag, t_v.iid, t_v.val)
    except Exception as e:
        print e
