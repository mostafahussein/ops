{% import_yaml "config/iscsi.yaml" as iscsi with context %}

{% if iscsi.enabled is defined %}
service.iscsi:
  pkg.installed:
    - name: open-iscsi
    - refresh: False
  service.running:
    - sig: /sbin/iscsid
    - name: open-iscsi
    - enable: True

/etc/init/iscsi-network-interface.override:
  file.absent

  {% for m in ("up", "down") %}
/etc/network/if-{{ m }}.d/open-iscsi:
  file.symlink:
    - mode: 644
    - user: root
    - group: root
    - target: ../../init.d/open-iscsi
  {% endfor %}
{% else %}
service.iscsi:
  service.dead:
    - sig: /sbin/iscsid
    - name: open-iscsi
    - enable: False

/etc/init/iscsi-network-interface.override:
  file.managed:
    - source: salt://common/etc/init/manual.override
    - mode: 644
    - user: root
    - group: root
    - template: jinja

  {% for m in ("up", "down") %}
/etc/network/if-{{ m }}.d/open-iscsi:
  file.absent
  {% endfor %}
{% endif %}

service.multipath-tools:
{% if iscsi.enabled_multipath is defined %}
  pkg.installed:
    - name: multipath-tools
    - refresh: False
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
