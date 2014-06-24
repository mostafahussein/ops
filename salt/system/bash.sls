{% import_yaml "config/bash.yaml" as bash with context %}

{% for f in bash.get('bash_profiles', ()) %}
/etc/profile.d/{{ f.name }}:
  {% if f.source is not defined %}
  file.absent
  {% else %}
  file.managed:
    - source: {{ f.source }}
    - mode: 644
    - user: root
    - group: root
  {% endif %}
{% endfor %}
