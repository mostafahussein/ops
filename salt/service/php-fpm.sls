{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.php-fpm:
  pkg.installed:
    - name: {{ pkgs.php | default('php') }}
    - refresh: False
  service.running:
    - name: php-fpm
    - enable: True
    - sig: "php-fpm: master process"
    - watch:
      - file: service.php-fpm
      - file: /etc/php/fpm-php5.5/php.ini
  file.managed:
    - name: /etc/php/fpm-php5.5/php-fpm.conf
    - source: salt://common/etc/php/fpm-php5.5/php-fpm.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        user: nobody
        group: nobody
        start_servers: 5

/etc/php/fpm-php5.5/php.ini:
  file.managed:
    - source: salt://common/etc/php/fpm-php5.5/php.ini
    - mode: 644
    - user: root
    - group: root
    - template: jinja
