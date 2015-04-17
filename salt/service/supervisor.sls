{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/supervisor.yaml" as supervisor with context %}

{% set svc_name = "supervisord" %}

{% if grains['os'] == "Ubuntu" %}
  {% set svc_name = "supervisor" %}
{% endif %}

service.supervisord:
  pkg.installed:
    - name: {{ pkgs.supervisor }}
    - refresh: False
{% if supervisor.enabled|default(True) %}
  service.running:
    - name: supervisord
    - enable: True
  {% if grains['os'] == "Gentoo" %}
    - sig: "supervisord --nodaemon"
  {% endif %}
    - watch:
      - file: service.supervisord
  file.managed:
    - name: /etc/supervisord.conf
    - source: salt://common/etc/supervisord.conf
    - mode: 0640
    - user: root
    - group: root
    - template: jinja
    - defaults:
        vars: {{ supervisor.programs }}
{% else %}
  service.dead:
    - name: supervisord
    - enable: False
  file.absent:
    - name: /etc/supervisord.conf
{% endif %}
