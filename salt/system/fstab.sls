/etc/fstab:
  file.managed:
    - source: salt://common/etc/fstab
    - mode: 644
    - user: root
    - group: root
    - template: jinja
