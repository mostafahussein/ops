{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.acpid:
  pkg.installed:
    - name: {{ pkgs.acpid | default('acpid') }}
    - refresh: False
  service.running:
    - name: acpid
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/sbin/acpid"
{% elif grains['os'] == "Ubuntu" %}
    - sig: "acpid -c /etc/acpi/events"
{% endif %}
