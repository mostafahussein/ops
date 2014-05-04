{% import_yaml "config/sysctl.yaml" as sysctl with context %}

service.sysctl:
  file.managed:
    - name: /etc/sysctl.d/default.conf
    - source: salt://common/etc/sysctl.d/default.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
  service.enabled:
{% if grains['os'] == "Gentoo" %}
    - name: sysctl
{% elif grains['os'] == "Ubuntu" %}
    - name: procps
{% endif %}
    - watch:
      - file: service.sysctl

{% if sysctl.settings is defined and sysctl.settings is iterable %}
  {% for setting in sysctl.settings %}
{{ setting.name }}:
  sysctl.present:
    - value: {{ setting.value }}
    - config: /etc/sysctl.d/default.conf
  {% endfor %}
{% endif %}
