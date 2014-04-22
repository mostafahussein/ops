{% import_yaml "config/apt.yaml" as apt with context %}

{% if grains['os'] == "Ubuntu" %}
/etc/apt/sources.list:
  file.managed:
    - source: salt://etc/apt/sources.list
    - user: root
    - group: root
    - mode: 0644
    - template: jinja

  {% if apt.sources is defined and
    apt.sources is iterable %}
    {% for f in apt.get("sources", ()) %}
/etc/apt/sources.list.d/{{ f.name }}:
  file.managed:
    - source: {{ f.source }}
    - user: root
    - group: root
    - mode: 0644
    - template: jinja
    {% endfor %}
  {% endif %}
{% endif %}
