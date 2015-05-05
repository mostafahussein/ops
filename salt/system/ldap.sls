{% import_yaml "config/ldap.yaml" as ldap with context %}
{% import_yaml "config/kerberos.yaml" as krb with context %}

{% if grains['os'] == "Ubuntu" %}
/etc/ldap/ldap.conf:
{% else %}
/etc/openldap/ldap.conf:
{% endif %}
  file.managed:
    - source: salt://common/etc/openldap/ldap.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja

/etc/ldap.conf:
  file.managed:
    - source: salt://common/etc/ldap-tpl.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        ldapuri: {{ ldap.ldapuri }}
        ssl: {{ ldap.ssl|default(False) }}
        group: {{ ldap.group }}
        domain: {{ krb.krb5_short }}
