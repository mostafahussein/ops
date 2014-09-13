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
  {% if grains['os'] in ("Gentoo", "Ubuntu") %}
    - exclude_pat: "E@(bash-completion.sh)"
  {% else %}
    - exclude_pat: "E@(colorls.csh)|(colorls.sh)|(glib2.csh)|(glib2.sh)|(lang.csh)|(lang.sh)|(less.csh)|(less.sh)|(vim.csh)|(vim.sh)|(which2.csh)|(which2.sh)"
  {% endif %}
{% endif %}
{% if profile_helpers %}
    - require:
  {% for f in profile_helpers %}
        - file: {{ f }}
  {% endfor %}
{% endif %}
