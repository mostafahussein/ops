{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.memcached:
  pkg.installed:
    - name: {{ pkgs.memcached | default("memcached") }}
    - refresh: False
  service.running:
    - name: memcached
    - enable: True
    - sig: "/usr/bin/memcached -d -p 11211"
  file.managed:
    - name: /etc/conf.d/memcached
    - source: salt://common/etc/conf.d/memcached
    - user: root
    - group: root
    - mode: 0644
    - template: jinja
    - defaults:
        listenon: "127.0.0.1"
