/etc/resolv.conf:
  file.managed:
    - source: salt://common/etc/resolv.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
