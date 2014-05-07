{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.in.tftpd:
  pkg.installed:
    - name: {{ pkgs.tftpd }}
    - refresh: False
  service.running:
    - name: in.tftpd
    - enable: True
    - sig: /usr/sbin/in.tftpd
    - watch:
      - file: service.in.tftpd
  file.managed:
    - name: /etc/conf.d/in.tftpd
    - source: salt://common/etc/conf.d/in.tftpd
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
