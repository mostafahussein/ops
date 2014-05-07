{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.mysqld:
  pkg.installed:
    - name: {{ pkgs.mysql | default('mysql') }}
    - refresh: False
  service.running:
    - name: mysqld
    - enable: True
    - name: mysql
    - sig: "/usr/sbin/mysqld --defaults-file=/etc/mysql/my.cnf"
    - watch:
      - file: service.mysqld
  file.managed:
    - name: /etc/mysql/my.cnf
    - source: salt://common/etc/mysql/my.cnf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        binlog_days: 30
