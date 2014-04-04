{% import_yaml "config/gateway.yaml" as gateway with context %}
{% import_yaml "config/sysctl.yaml" as sysctl with context %}

service.sysctl:
  file.managed:
    - name: /etc/sysctl.d/default.conf
    - source: salt://common/etc/sysctl.d/default.conf
    - mode: 644
    - user: root
    - group: root
  service.enabled:
{% if grains['os'] == "Gentoo" %}
    - name: sysctl
{% elif grains['os'] == "Ubuntu" %}
    - name: procps
{% endif %}
    - watch:
      - file: service.sysctl
      - file: /etc/sysctl.d/rp_filter.conf
{% if sysctl.files is defined and sysctl.files is iterable %}
  {% for f in sysctl.files %}
      - file: /etc/sysctl.d/{{ f.name }}
  {% endfor %}
{% endif %}
{% if gateway.is_gateway is defined %}
      - file: /etc/sysctl.d/gw.conf

/etc/sysctl.d/gw.conf:
  file.managed:
    - source: salt://common/etc/sysctl.d/gw.conf
    - mode: 644
    - user: root
    - group: root
{% else %}
/etc/sysctl.d/gw.conf:
  file.absent
{% endif %}

/etc/sysctl.d/rp_filter.conf:
  file.managed:
    - source: salt://common/etc/sysctl.d/rp_filter.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja

{% if sysctl.files is defined and sysctl.files is iterable %}
  {% for f in sysctl.files %}
/etc/sysctl.d/{{ f.name }}:
  file.managed:
    - source: {{ f.src }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
  {% endfor %}
{% endif %}
