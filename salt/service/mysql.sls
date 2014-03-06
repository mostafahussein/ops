service.mysqld:
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
