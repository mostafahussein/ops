/etc/openldap/ldap.conf:
  file.managed:
    - source: salt://common/etc/openldap/ldap.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
