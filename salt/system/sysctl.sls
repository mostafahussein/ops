{% import_yaml "config/sysctl.yaml" as sysctl with context %}

service.sysctl:
  file.managed:
    - name: /etc/sysctl.d/default.conf
    - source: salt://common/etc/sysctl.d/default.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
{% if grains['os'] != "CentOS" %}
  {# @todo add sysctl reload for centos #}
  service.enabled:
  {% if grains['os'] == "Gentoo" %}
    - name: sysctl
  {% elif grains['os'] == "Ubuntu" %}
    - name: procps
  {% endif %}
    - watch:
      - file: /etc/sysctl.conf
      - file: service.sysctl
{% endif %}

{% if sysctl.settings is defined and sysctl.settings is iterable %}
  {% for setting in sysctl.settings %}
{{ setting.name }}:
  sysctl.present:
    - value: {{ setting.value }}
    - config: /etc/sysctl.d/default.conf
  {% endfor %}
{% endif %}

/etc/sysctl.conf:
  file.managed:
    - mode: 644
    - user: root
    - group: root
    - source: salt://common/etc/sysctl.conf.{{ grains['os'] | lower }}
