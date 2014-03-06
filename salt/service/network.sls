{% if grains['os'] == "Gentoo" %}

{%- import_yaml "config/nics.yaml" as nics with context -%}

/etc/conf.d/net:
  file.managed:
    - source: salt://etc/conf.d/net.{{ grains['id'] }}
    - mode: 0644
    - user: root
    - group: root

{% for i in nics.get('nics', []) %}
service.net.{{ i }}:
  service.enabled:
    - name: net.{{ i }}
  file.symlink:
    - name: /etc/init.d/net.{{ i }}
    - target: net.lo
{% endfor %}

{% endif %}
