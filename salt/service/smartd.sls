{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/smartd.yaml" as smartd with context %}

service.smartd:
  pkg.installed:
    - name: {{ pkgs.smartmontools | default('smartmontools') }}
    - refresh: False
{% if grains.get('virtual') == 'physical' and
  smartd.svc_enabled|default(True) %}
  service.running:
    - enable: True
    - watch:
        - file: service.smartd
  {% if grains['os'] == "Ubuntu" %}
        - file: /etc/default/smartmontools
  {% endif %}
{% else %}
  service.dead:
    - enable: False
{% endif %}
    - name: smartd
    - sig: "/usr/sbin/smartd"
  file.managed:
    - user: root
    - group: root
    - mode: "0644"
    - template: jinja
    - name: /etc/smartd.conf
    - source: salt://common/etc/smartd.conf.{{ grains['os'] | lower }}

{% if grains['os'] == "Ubuntu" %}
/etc/default/smartmontools:
  file.managed:
    - user: root
    - group: root
    - mode: "0644"
    - template: jinja
    - source: salt://common/etc/default/smartmontools
{% endif %}
