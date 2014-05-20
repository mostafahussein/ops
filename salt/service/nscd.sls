{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.nscd:
  pkg.installed:
    - name: {{ pkgs.nscd | default('nscd') }}
    - refresh: False
  service.running:
    - name: nscd
    - enable: True
{% if grains['os'] == "Ubuntu" %}
    - sig: "/usr/sbin/nscd"
{% endif %}
