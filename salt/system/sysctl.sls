{% import_yaml "config/gateway.yaml" as gateway with context %}

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
{% if gateway.is_gateway %}
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
