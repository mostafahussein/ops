{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/ntp.yaml" as ntp with context %}

service.ntpd:
  pkg.installed:
    - name: {{ pkgs.ntp | default('ntp') }}
    - refresh: False
  service.running:
{% if grains['os'] == "Ubuntu" %}
    - name: ntp
{% else %}
    - name: ntpd
{% endif %}
    - enable: True
    - sig: /usr/sbin/ntpd
    - watch:
      - file: service.ntpd
  file.managed:
    - name: /etc/ntp.conf
{% if ntp.is_server is defined  %}
    - source: salt://common/etc/ntp-server.conf
{% else %}
    - source: salt://common/etc/ntp-client.conf
{% endif %}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
