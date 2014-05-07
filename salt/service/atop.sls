{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.atop:
  pkg.installed:
    - name: {{ pkgs.atop | default('atop') }} 
    - refresh: False
  service.running:
    - name: atop
    - enable: True
    - sig: "/usr/bin/atop -a -w"

/etc/cron.d/atop:
{% if grains['os'] == "Gentoo" %}
  file.managed:
    - source: salt://common/etc/cron.d/atop
    - mode: 644
    - user: root
    - group: root
{% else %}
  file.absent
{% endif %}
