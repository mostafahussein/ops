{% import_yaml "config/ssl.yaml" as ssl with context %}
{% if ssl.ssl_ca is defined %}
  {% for s in ssl.get('ssl_ca', ()) %}
/etc/ssl/{{ s }}:
  file.managed:
    - source: salt://etc/ssl/{{ s }}
    - mode: 644
    - user: root
    - group: root
    - makedirs: True
  {% endfor %}
{% endif %}
