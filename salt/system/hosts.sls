/etc/hosts:
  file.managed:
    - source:
      - salt://etc/hosts.{{ grains['os'] | lower }}
      - salt://common/etc/hosts.{{ grains['os'] | lower }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
