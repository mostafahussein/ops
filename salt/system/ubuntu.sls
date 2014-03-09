{% for f in (
  "default/rcS",
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
