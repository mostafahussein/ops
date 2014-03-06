{% import_yaml "config/bash.yaml" as bash with context %}

{% for f in bash.get('bash_profiles', ()) %}
/etc/profile.d/{{ f.name }}:
  file.managed:
{% if f.target is defined %}
    - source: {{ f.target }}
{% else %}
    - source: salt://common/etc/profile.d/{{ f.name }}
{% endif %}
    - mode: 644
    - user: root
    - group: root
{% endfor %}
