{% import_yaml "config/iscsi.yaml" as iscsi with context %}

service.iscsi:
{% if iscsi.enabled is defined %}
  service.running:
    - enable: True
{% else %}
  service.dead:
    - enable: False
{% endif %}
    - sig: /sbin/iscsid
    - name: open-iscsi

service.multipath-tools:
{% if iscsi.enabled_multipath is defined %}
  service.running:
    - enable: True
    - watch:
      - file: /etc/multipath.conf
{% else %}
  service.dead:
    - enable: False
{% endif %}
    - sig: /sbin/multipathd
    - name: multipath-tools

/etc/rcS.d/S21multipath-tools-boot:
{% if iscsi.enabled_multipath is defined %}
  file.symlink:
    - user: root
    - group: root
    - target: ../init.d/multipath-tools-boot

kmod.dm_multipath:
  kmod.present:
    - name: dm_multipath

/etc/multipath.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - source: {{ iscsi.multipath_conf }}
    - template: jinja
{% else %}
  file.absent

/etc/multipath.conf:
  file.absent

kmod.dm_multipath:
  kmod.absent:
    - name: dm_multipath
{% endif %}
