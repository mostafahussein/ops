{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.mcelog:
{% if grains.get('virtual') != 'physical' or
  grains['cpu_model'].startswith("AMD") %}
  service.dead:
    - enable: False
{% else %}
  pkg.installed:
    - name: {{ pkgs.mcelog | default('mcelog') }}
    - refresh: False
  service.running:
    - enable: True
{% endif %}
    - sig: /usr/sbin/mcelog
    - name: mcelog
