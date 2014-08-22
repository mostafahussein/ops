{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/mysql.yaml" as mysql with context %}

{% set pkg_name = mysql.pkg|default('mariadb') %}

service.mysqld:
  pkg.installed:
    - name: {{ pkgs.get(pkg_name) }}
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
