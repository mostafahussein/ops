service.acpid:
  service.running:
    - name: acpid
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/sbin/acpid"
{% elif grains['os'] == "Ubuntu" %}
    - sig: "acpid -c /etc/acpi/events"
{% endif %}
