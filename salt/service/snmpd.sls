service.snmpd:
  file.managed:
    - name: /etc/snmp/snmpd.conf
    - source: salt://etc/snmp/snmpd.conf
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
{% if grains['os'] == "Gentoo" %}
      - file: /etc/conf.d/snmpd

/etc/conf.d/snmpd:
  file.managed:
    - source: salt://common/etc/conf.d/snmpd
    - mode: 0644
    - user: root
    - group: root

/etc/default/snmpd:
  file.absent

{% elif grains['os'] == "Ubuntu" %}
      - file: /etc/default/snmpd

/etc/conf.d/snmpd:
  file.absent

/etc/default/snmpd:
  file.managed:
    - source: salt://common/etc/default/snmpd
    - mode: 0644
    - user: root
    - group: root
{% endif %}
