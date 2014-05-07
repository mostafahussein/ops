{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/samba.yaml" as samba with context %}

{% if samba.get('samba_enabled') %}
service.samba:
  pkg.installed:
    - name: {{ pkgs.samba | default('samba') }}
    - refresh: False
  service.running:
    - name: samba
    - enable: True
    - sig: "/usr/sbin/smbd -D"
    - watch:
      - file: service.samba
  file.managed:
    - name: /etc/samba/smb.conf
    - mode: 644
    - user: root
    - group: root
    - source: salt://etc/samba/smb.conf.{{ samba['samba_name'] }}
{% endif %}
