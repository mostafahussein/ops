{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.snmpd:
  pkg.installed:
    - name: {{ pkgs.snmpd | default('snmpd') }}
    - refresh: False
  file.managed:
    - name: /etc/snmp/snmpd.conf
    - source:
      - salt://etc/snmp/snmpd.conf
      - salt://common/etc/snmp/snmpd.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
  service.running:
    - name: snmpd
    - enable: True
    - sig: "/usr/sbin/snmpd"
    - watch:
      - file: service.snmpd
      - file: config.snmpd

config.snmpd:
  file.managed:
{% if grains['os'] == "Gentoo" %}
    - name: /etc/conf.d/snmpd
{% elif grains['os'] == "Ubuntu" %}
    - name: /etc/default/snmpd
{% elif grains['os'] == "CentOS" %}
    - name: /etc/sysconfig/snmpd
{% endif %}
    - source:
      - salt://etc/conf.d/snmpd.{{ grains['os'] | lower }}
      - salt://common/etc/conf.d/snmpd.{{ grains['os'] | lower }}
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
