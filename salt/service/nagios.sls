{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.nagios:
  pkg.installed:
    - name: {{ pkgs.nagios | default('nagios') }}
    - refresh: False
  service.running:
    - name: nagios
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/sbin/nagios -d /etc/nagios/nagios.cfg"
{% endif %}
