service.dhcpd:
  service.running:
    - name: dhcpd
    - enable: True
    - sig: "/usr/sbin/dhcpd -cf /etc/dhcp/dhcpd.conf -q"
    - watch:
      - file: service.dhcpd
  file.managed:
    - name: /etc/dhcp/dhcpd.conf
    - source: salt://etc/dhcp/dhcpd.conf
    - mode: 0644
    - user: root
    - group: root
