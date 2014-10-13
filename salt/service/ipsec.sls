{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/ipsec.yaml" as ipsec with context %}

service.ipsec:
  pkg.installed:
    - name: {{ pkgs.ipsec }}
    - refresh: False
{% if ipsec.srv_ipsec_enabled|default(False) %}
  {% if ipsec.srv_ipsec_running|default(False) %}
  service.running:
  {% else %}
  service.disabled:
  {% endif %}
{% else %}
  service.dead:
{% endif %}
    - name: ipsec
    - enable: {{ ipsec.enable_srv_ipsec|default(False) }}
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/libexec/ipsec/pluto --config /etc/ipsec.conf"
{% elif grains['os'] == "Ubuntu" %}
    - sig: "/usr/lib/ipsec/pluto --nofork"
{% endif %}

service.xl2tpd:
  pkg.installed:
    - name: {{ pkgs.xl2tpd|default('xl2tpd') }}
    - refresh: False
{% if ipsec.srv_xl2tpd_enabled|default(False) %}
  {% if ipsec.srv_xl2tpd_running|default(False) %}
  service.running:
  {% else %}
  service.disabled:
  {% endif %}
{% else %}
  service.dead:
{% endif %}
    - name: xl2tpd
    - enable: {{ ipsec.enable_srv_xl2tpd|default(False) }}
    - sig: "/usr/sbin/xl2tpd"

{% for f in ipsec.confs|default(()) %}
{{ f.name }}:
  file.managed:
    - source:
  {% if f.source is defined %}
        - {{ f.source }}
  {% endif %}
        - salt:/{{ f.name }}
    - user: root
    - group: root
    - mode: {{ f.mode|default('0644') }}
    - template: jinja
  {% if f.variables is defined %}
    - defaults:
        vars: {{ f.variables }}
  {% endif %}
{% endfor %}
