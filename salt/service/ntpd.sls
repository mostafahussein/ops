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
{% if grains['os'] == "CentOS" %}
    - sig: "ntpd -p /var/run/ntpd.pid -g"
{% else %}
    - sig: "/usr/sbin/ntpd -p /var/run/ntpd.pid -g"
{% endif %}
    - watch:
      - file: service.ntpd
      - file: config.ntpd
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

config.ntpd:
  file.managed:
{% if grains['os'] == "Ubuntu" %}
    - name: /etc/default/ntp
{% elif grains['os'] == "CentOS" %}
    - name: /etc/sysconfig/ntpd
{% elif grains['os'] == "Gentoo" %}
    - name: /etc/conf.d/ntpd
{% endif %}
    - source: salt://common/etc/conf.d/ntpd.{{ grains['os'] | lower }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
