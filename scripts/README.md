# sso_update

create ldap_cfg.yaml
<pre>
uri: ldapi://
basedn: dc=demo,dc=local
default_ou: demo_users
bind_dn: cn=ops,ou=Control
bind_pass: password
krb5_realm: DEMO.LOCAL
krb5_passwd: "kadmin.local -q 'ank -pw %s %s'"

# vim: ts=2 filetype=yaml
</pre>

prepare user info.

<pre>
# uid | sn | givenName | mail | password | mobile | group
</pre>

./user2yaml.awk user > user.yaml

./sso_update
