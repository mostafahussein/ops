service.nagios:
  service.running:
    - name: nagios
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/sbin/nagios -d /etc/nagios/nagios.cfg"
{% endif %}
