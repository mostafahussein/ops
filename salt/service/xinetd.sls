{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/xinetd.yaml" as xinetd with context %}

service.xinetd:
{% if xinetd.disabled is defined %}
  service.dead:
    - name: xinetd
    - enable: False
{% else %}
  pkg.installed:
    - name: {{ pkgs.xinetd | default('xinetd') }}
    - refresh: False
  service.running:
    - name: xinetd
    - enable: True
  {% if grains['os'] == "CentOS" %}
    - sig: "xinetd -stayalive"
  {% endif %}
{% endif %}
