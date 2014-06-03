{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/nagios.yaml" as nagios with context %}

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

{% if nagios.config is defined %}
  {% for f in nagios.config %}
/etc/nagios/{{ f.name }}:
  file.managed:
    - source:
    {% if f.source is defined %}
      - {{ f.source }}
    {% endif %}
      - salt://etc/nagios/{{ f.name }}
      - salt://common/etc/nagios/{{ f.name }}
    - user: root
    - group: root
    - mode: 0644
    - template: jinja
  {% endfor %}
{% endif %}
