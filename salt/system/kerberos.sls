/etc/krb5.conf:
  file.managed:
    - source: salt://common/etc/krb5.conf
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
