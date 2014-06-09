{% import_yaml "config/sysctl.yaml" as sysctl with context %}

service.sysctl:
{% if grains['os'] == "CentOS" %}
  file.directory:
    - name: /etc/sysctl.d/
    - mode: 755
    - user: root
    - group: root
{% else %}
  service.enabled:
  {% if grains['os'] == "Gentoo" %}
    - name: sysctl
  {% elif grains['os'] == "Ubuntu" %}
    - name: procps
  {% endif %}
    - watch:
      - file: /etc/sysctl.conf
      - file: /etc/sysctl.d/default.conf
{% endif %}

/etc/sysctl.d/default.conf:
  file.managed:
    - source: salt://common/etc/sysctl.d/default.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja

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
