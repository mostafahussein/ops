{% import_yaml "config/bash.yaml" as bash with context %}

{% set profile_helpers = [] %}

{% for f in bash.get('bash_profiles', ()) %}
/etc/profile.d/{{ f.name }}:
  {% if f.source is not defined %}
  file.absent
  {% else %}
    {% do profile_helpers.append("".join(("/etc/profile.d/", f.name))) %}
  file.managed:
    - source: {{ f.source }}
    - mode: 644
    - user: root
    - group: root
  {% endif %}
{% endfor %}

/etc/profile.d:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - clean: True
{% if bash.profile_d_exclude is defined %}
    - exclude_pat: {{ bash.profile_d_exclude }}
{% else %}
  {% if grains['os'] in ("Gentoo",) %}
    - exclude_pat: "E@^(bash-completion\\.sh|colorsvn-env\\.sh|java-config-2\\.c?sh)$"
  {% elif grains['os'] in ("Ubuntu",) %}
    - exclude_pat: "E@^bash_completion\\.sh$"
  {% else %}
    - exclude_pat: "E@^(colorls\\.c?sh|glib2\\.c?sh|lang\\.c?sh|less\\.c?sh|vim\\.c?sh|which2\\.c?sh)$"
  {% endif %}
{% endif %}
{% if profile_helpers %}
    - require:
  {% for f in profile_helpers %}
        - file: {{ f }}
  {% endfor %}
{% endif %}
