{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.atop:
  pkg.installed:
    - name: {{ pkgs.atop | default('atop') }}
    - refresh: False
  service.running:
    - name: atop
    - enable: True
    - sig: "/usr/bin/atop -a -w"
