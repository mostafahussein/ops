{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.sshd:
  pkg.installed:
    - name: {{ pkgs.sshd }}
    - refresh: False
  service.running:
{% if grains['os'] == "Ubuntu" %}
    - name: ssh
{% else %}
    - name: sshd
{% endif %}
    - enable: True
    - sig: /usr/sbin/sshd
    - watch:
      - file: service.sshd
  file.managed:
    - name: /etc/ssh/sshd_config
    - source: salt://common/etc/ssh/sshd_config.{{ grains['os'] | lower }}
    - mode: 0600
    - user: root
    - group: root
    - template: jinja
