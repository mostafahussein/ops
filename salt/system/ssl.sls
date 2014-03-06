{%- import_yaml "config/ssl.yaml" as ssl with context -%}
{% for s in ssl.get('ssl_ca', ()) %}
/etc/ssl/{{ s }}:
  file.managed:
    - source: salt://etc/ssl/{{ s }}
    - mode: 644
    - user: root
    - group: root
{% endfor %}
