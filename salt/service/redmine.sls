{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.redmine:
  pkg.installed:
    - name: {{ pkgs.redmine }}
    - refresh: False
  service.running:
    - name: redmine
    - enable: True
    - sig: "/usr/bin/ruby /var/lib/redmine/script/rails"
