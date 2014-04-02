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
