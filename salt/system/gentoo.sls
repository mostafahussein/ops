{% import_yaml "config/udev.yaml" as udev with context %}

service.netmount:
  service.disabled:
    - name: netmount

eselect.profile:
  eselect.set:
    - name: profile
    - target: hardened/linux/amd64

/etc/inittab:
  file.managed:
    - source: salt://common/etc/inittab
    - mode: 644
    - user: root
    - group: root
    - template: jinja

/etc/securetty:
  file.managed:
    - source: salt://common/etc/securetty.gentoo
    - mode: 600
    - user: root
    - group: root

/etc/updatedb.conf:
  file.managed:
    - source: salt://common/etc/updatedb.conf.gentoo
    - mode: 644
    - user: root
    - group: root
    - template: jinja

/etc/env.d/99local:
  file.managed:
    - source: salt://common/etc/env.d/99local
    - mode: 644
    - user: root
    - group: root

/etc/udev/rules.d/70-persistent-net.rules:
  file.absent

/etc/udev/rules.d/80-net-name-slot.rules:
{% if udev.predictable_nic_name is defined %}
  file.absent
{% else %}
  file.symlink:
    - user: root
    - group: root
    - target: /dev/null
{% endif %}

/etc/timezone:
  file.managed:
    - source: salt://common/etc/timezone
    - mode: 644
    - user: root
    - group: root

/etc/conf.d/hwclock:
  file.managed:
    - source: salt://common/etc/conf.d/hwclock
    - mode: 644
    - user: root
    - group: root
