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
