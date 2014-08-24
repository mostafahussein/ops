{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/lvm.yaml" as lvm with context %}

service.lvm:
  pkg.installed:
    - name: {{ pkgs.lvm2 | default('lvm2') }}
    - refresh: False
{% if lvm.enabled|default(False) %}
  {% if grains['os'] == "Gentoo" %}
  file.symlink:
    - name: /etc/runlevels/boot/lvm
    - target: /etc/init.d/lvm
  {% endif %}
{% endif %}
