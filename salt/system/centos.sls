{% if grains['os'] == "CentOS" %}

/etc/selinux/config:
  file.managed:
    - source: salt://common/etc/selinux/config
    - mode: 644
    - user: root
    - group: root
    - template: jinja

/run:
  file.symlink:
    - target: /var/run

/etc/rc.d/rc.local:
  file.managed:
    - source: salt://common/etc/rc.local.{{ grains['os'] | lower }}
    - mode: 755
    - user: root
    - group: root
    - template: jinja

/etc/rc.local:
  file.symlink:
    - target: rc.d/rc.local
    - user: root
    - group: root
{% endif %}
