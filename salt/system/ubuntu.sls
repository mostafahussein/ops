{% if grains['os'] == "Ubuntu" %}

  {% for f in (
    "default/rcS",
    "init/failsafe.conf",
    "initramfs-tools/initramfs.conf",
    "initramfs-tools/update-initramfs.conf",
    "kernel-img.conf",
    "timezone") %}
/etc/{{ f }}:
  file.managed:
    - source: salt://common/etc/{{ f }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
  {% endfor %}

/etc/rc.local:
  file.managed:
    - source: salt://common/etc/rc.local.{{ grains['os'] | lower }}
    - mode: 755
    - user: root
    - group: root

{% endif %}
