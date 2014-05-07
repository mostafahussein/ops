{% import_yaml "common/config/packages.yaml" as pkgs with context %}

service.sshd:
  pkg.installed:
    - name: {{ pkgs.sshd }}
    - refresh: False
  service.running:
{% if grains['os'] == "Gentoo" %}
    - name: sshd
{% elif grains['os'] == "Ubuntu" %}
    - name: ssh
{% endif %}
    - enable: True
    - sig: /usr/sbin/sshd
    - watch:
      - file: service.sshd
  file.managed:
    - name: /etc/ssh/sshd_config
{% if grains['os'] == "Gentoo" %}
    - source: salt://common/etc/ssh/sshd_config.gentoo
{% elif grains['os'] == "Ubuntu" %}
    - source: salt://common/etc/ssh/sshd_config.ubuntu
{% endif %}
    - mode: 0600
    - user: root
    - group: root
    - template: jinja
