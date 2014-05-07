{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.dhcpd:
  pkg.installed:
    - name: {{ pkgs.dhcpd }}
    - refresh: False
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
