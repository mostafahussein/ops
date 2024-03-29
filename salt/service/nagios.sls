{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/nagios.yaml" as nagios with context %}

{% set nagios_cfgs = [] %}

{% if nagios.config is defined %}
  {% for l in nagios.config %}
{{ l.location }}:
  file.directory:
    - user: {{ l.user|default('root') }}
    - group: {{ l.group|default('root') }}
    - mode: {{ l.mode|default('0755') }}
    - clean: True
    {% if l.exclude is defined %}
    - exclude_pat: {{ l.exclude }}
    {% else %}
      {% if grains['os'] == "Gentoo" %}
    - exclude_pat: ".keep*"
      {% endif %}
    {% endif %}
    {% if l.configs|default(False) %}
    - require:
      {% for f in l.configs %}
        {% do nagios_cfgs.append('/'.join((l.location, f.name))) %}
      - file: {{ l.location }}/{{ f.name }}
      {% endfor %}
      {% for f in l.configs %}
{{ l.location }}/{{ f.name }}:
  file.managed:
    - source:
        {% if f.source is defined %}
      - {{ f.source }}
        {% endif %}
      - salt:/{{ l.location }}/{{ f.name }}
    - user: {{ f.user|default('root') }}
    - group: {{ f.group|default('root') }}
    - mode: {{ f.mode|default('0644') }}
    - template: jinja
      {% endfor %}
    {% endif %}
  {% endfor %}
{% endif %}

service.nagios:
  pkg.installed:
    - name: {{ pkgs.nagios | default('nagios') }}
    - refresh: False
  service.running:
    - name: nagios
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/sbin/nagios -d /etc/nagios/nagios.cfg"
{% endif %}
{% if nagios_cfgs %}
    - watch:
  {% for l in nagios_cfgs %}
        - file: {{ l }}
  {% endfor %}
{% endif %}
