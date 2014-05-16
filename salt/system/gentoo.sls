{% import_yaml "config/udev.yaml" as udev with context %}

{% if grains['os'] == "Gentoo" %}

service.netmount:
  service.disabled:
    - name: netmount

eselect.profile:
  eselect.set:
    - name: profile
    - target: hardened/linux/amd64

  {% for f in ("conf.d/hwclock", "env.d/99local", "inittab", "locale.gen",
    "timezone") %}
/etc/{{ f }}:
  file.managed:
    - source: salt://common/etc/{{ f }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
  {% endfor %}

# watch /etc/inittab

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

{% endif %}
