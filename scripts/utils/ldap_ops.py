#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import yaml
import traceback

try:
    import ldap
    import ldap.modlist
except ImportError:
    sys.stderr.write("python ldap module not found")
    sys.exit(1)


class LDAPError(Exception):
    def __init__(self, msg):
        self.msg = msg

    def __str__(self):
        return self.msg


class ldap_ops:
    def __init__(self, **kwargs):
        yaml_cfg = kwargs.get("yaml", "ldap_cfg.yaml")
        try:
            ldap_cfg = yaml.load(open(yaml_cfg, "r"))
        except Exception as e:
            raise LDAPError("** yaml load failed: %s" % (e,))

        self.basedn = {}
        self.basedn["root"] = ldap_cfg.get("basedn")
        if not self.basedn["root"]:
            raise LDAPError("** basedn must be provided")

        ldap_uri = ldap_cfg.get("uri", "ldapi://")

        try:
            # @todo fix options
            ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_NEVER)
            self.ldapobject = ldap.initialize(ldap_uri)

            # check bind_dn, if no pass, ask
            bind_dn = ldap_cfg.get("bind_dn")
            if bind_dn:
                bind_pass = ldap_cfg.get("bind_pass")
                if not bind_pass:
                    raise LDAPError("** bind dn provided w/o password")
                bind_dn = ",".join((bind_dn, self.basedn["root"]))
                if not self.ldapobject.bind_s(bind_dn, bind_pass):
                    raise LDAPError("** bind on `%s' failed" % (ldap_uri,))
            else:
                #if not self.ldapobject.simple_bind_s():
                #    raise LDAPError("** bind on `%s' failed" % (ldap_uri,))
                pass
        except LDAPError:
            raise
        except:
            raise LDAPError("** %s" % (traceback.format_exc(),))

        user_dn = kwargs.get("user", "ou=People")
        group_dn = kwargs.get("group", "ou=Group")
        leave_dn = kwargs.get("user", "ou=Leave")
        self.basedn["user"] = ",".join((user_dn, self.basedn["root"]))
        self.basedn["group"] = ",".join((group_dn, self.basedn["root"]))
        self.basedn["leave"] = ",".join((leave_dn, self.basedn["root"]))

        self.first_uid = kwargs.get("uidNumber_first", 10000)

        self.user_filters = "(&(uid=%s)(objectClass=posixAccount))"
        self.group_filters = "(&(cn=%s)(objectClass=posixGroup))"

        self.default_ou = ldap_cfg.get("default_ou")
        if not self.default_ou:
            raise LDAPError("** default ou not defined")
        args = {
            'basedn': self.basedn['group'],
            'filters': self.group_filters % self.default_ou,
            'attrs': ['gidNumber'],
        }
        groups = [l[1].get('gidNumber')[0] for l in self.query(**args)]
        if not groups or len(groups) > 1:
            raise LDAPError("** default ou number not unique")
        self.default_gidNumber = groups[0]

        self.krb5_realm = ldap_cfg.get("krb5_realm")
        if not self.krb5_realm:
            raise LDAPError("** krb5 realm not defined")

        self.krb5_passwd = ldap_cfg.get("krb5_passwd")
        if not self.krb5_passwd:
            raise LDAPError("** krb5 passwd program not defined")

    def __del__(self):
        self.ldapobject.unbind()

    def query(self, **kwargs):
        basedn = kwargs.get("basedn", self.basedn["root"])
        if basedn in self.basedn:
            basedn = self.basedn.get(basedn)
        filters = kwargs.get("filters", "(objectClass=*)")
        attrs = kwargs.get("attrs", None)
        return self.ldapobject.search_s(basedn, ldap.SCOPE_SUBTREE,
                                        filters, attrs)

    def query_users(self, **kwargs):
        args = {
            'basedn': 'user',
            'filters' : kwargs.get("filters", self.user_filters % '*'),
            'attrs' : kwargs.get("attrs", None)
        }
        return self.query(**args)

    def get_next_uidNumber(self):
        args = {
            'filters': self.user_filters % '*',
            'attrs': ['uidNumber'],
        }
        args['basedn'] = 'user'
        users = self.query(**args)
        args['basedn'] = 'leave'
        leaves = self.query(**args)

        uidNumbers = [l[1].get('uidNumber')[0] for l in users + leaves]
        if uidNumbers:
            return int(max(uidNumbers)) + 1
        else:
            return int(self.first_uid)
        pass

    def user_add(self, user):
        user_tpl = {
            "loginShell": "/bin/bash",
            "objectClass": [
                "person",
                "posixAccount",
                "inetOrgPerson",
                "organizationalPerson"
                ],
            "userPassword": "".join(("{SASL}%s@", self.krb5_realm)),
            "homeDirectory": "/home/users/%s",
        }

        # check uid is unique
        uid = user.get('uid')
        args = {
            'attrs': ['uid'],
            'filters': self.user_filters % uid,
        }
        args['basedn'] = 'user'
        users = self.query(**args)
        args['basedn'] = 'leave'
        leaves = self.query(**args)
        uids = [l[1].get('uid')[0] for l in users + leaves]
        if users or leaves:
            print("!! uid `%s' has been used, please change it" % uid)
            #return

        password = user.get('password')
        if password:
            user.pop('password')

        dn = ','.join(("uid=%s", self.basedn["user"])) % uid
        if not user.get('uidNumber'):
            user['uidNumber'] = self.get_next_uidNumber()
        if not user.get('userPassword'):
            user['userPassword'] = user_tpl['userPassword'] % uid
        if not user.get('gidNumber'):
            user['gidNumber'] = str(self.default_gidNumber)
        if not user.get('homeDirectory'):
            user['homeDirectory'] = user_tpl['homeDirectory'] % (uid)
        if not user.get('ou'):
            user['ou'] = self.default_ou
        attrs = {}
        for k, v in user.items():
            if not isinstance(v, list):
                v = [str(v)]
            attrs[k] = v
        for k, v in user_tpl.items():
            if k in user: continue
            if not isinstance(v, list):
                v = [str(v)]
            attrs[k] = v
        print(">> Add user `%s'" % uid)
        self.ldapobject.add_ext_s(dn, ldap.modlist.addModlist(attrs))

        if password:
            passwd_cmd = self.krb5_passwd % (password, uid)
            ret = os.system(passwd_cmd)
            if ret != 0:
                print("!! passwd set failed, please check `%s'" % passwd_cmd)

    def update_group_from_users(self):
        user_args = {
            'attrs': ['ou', 'uid'],
            'basedn': 'user',
            'filters': self.user_filters % '*',
        }
        group_args = {
            'attrs': ['cn', 'memberUid'],
            'basedn': 'group',
            'filters': self.group_filters % '*',
        }

        print(">> Update Group from Users (if any)")
        groups = {}
        for user in self.query(**user_args):
            uid = user[1].get('uid')[0]
            for ou in user[1].get('ou'):
                if ou not in groups:
                    groups[ou] = []
                groups[ou].append(uid)
        for grp in self.query(**group_args):
            ou = grp[1].get('cn')[0]
            grp_modlist = []
            for uid in groups.get(ou):
                if uid in grp[1].get('memberUid'): continue
                grp_modlist.append((ldap.MOD_ADD, "memberUid", uid))
            for uid in grp[1].get('memberUid'):
                if uid in groups.get(ou): continue
                grp_modlist.append((ldap.MOD_DELETE, "memberUid", uid))
            if grp_modlist:
                print(" >> Group `%s'" % ou)
                for op in grp_modlist:
                    if op[0] == ldap.MOD_ADD:
                        print("  >> add `%s'" % op[2])
                    elif op[0] == ldap.MOD_DELETE:
                        print("  >> del `%s'" % op[2])
            self.ldapobject.modify_ext_s(grp[0], grp_modlist)
