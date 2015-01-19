{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/openvpn.yaml" as openvpn with context %}

{% if grains['os'] == "Gentoo" %}
{% set user = "openvpn" %}
{% set group = "openvpn" %}
{% else %}
{% set user = "root" %}
{% set group = "root" %}
{% endif %}

pkg.openvpn:
  pkg.installed:
    - name: {{ pkgs.openvpn | default('openvpn') }}
    - refresh: False

{#
/etc/openvpn:
  file.recurse:
    - source: salt://etc/openvpn/common
    - exclude_pat: .svn
    - include_empty: True
    - dir_mode: '0755'
    - file_mode: '0400'
    - user: {{ user }}
    - group: {{ group }}
#}

{% for f in openvpn.get('openvpn_scripts', ()) %}
{{ f.name }}:
  {% if f.get('disabled') %}
  file.absent
  {% else %}
  file.managed:
    - source: {{ f.source }}
    - mode: '0500'
    - user: {{ user }}
    - group: {{ group }}
    - template: jinja
    {% if f.location is defined %}
    - defaults:
       location: {{ f.location }}
    {% endif %}
  {% endif %}
{% endfor %}


{% for f in openvpn.get('openvpn_configs', ()) %}
{{ f.name }}:
  {% if f.get('enabled') %}
  file.managed:
    - source: {{ f.source }}
    - mode: 0400
    - user: {{ user }}
    - group: {{ group }}
    - template: jinja
    {% if f.attrs is defined or f.location is defined %}
    - defaults:
      {% if f.attrs is defined %}
        attrs: {{ f.attrs }}
      {% endif %}
      {% if f.location is defined %}
        location: {{ f.location }}
      {% endif %}
    {% endif %}
  {% else %}
  file.absent
  {% endif %}
{% endfor %}

{% for f in openvpn.get('openvpn_files', ()) %}
  {% if f.type == "dir" %}
{{ f.name }}:
  file.directory:
    - user: {{ user }}
    - group: {{ group }}
    - mode: 0700
  {% elif f.type == "file" %}
{{ f.name }}:
  file.managed:
    {% if f.source is defined %}
    - source: {{ f.source }}
      {% if f.attrs is defined %}
    - defaults:
        attrs: {{ f.attrs }}
      {% endif %}
    {% else %}
    - replace: False
    {% endif %}
    - user: {{ f.user | default(user) }}
    - group: {{ f.group | default(group) }}
    - mode: {{ f.mode | default('0400') }}
    - template: jinja
  {% elif f.type == "symlink" %}
{{ f.name }}:
  file.symlink:
    - target: {{ f.target }}
  {% elif f.type == "ccds" %}
    {% import_yaml f.name as ccds with context -%}
    {% set ccd_list = [] %}
    {% if ccds.configs is defined %}
      {% for c in ccds.configs.get(ccds.config_key, ()) %}
        {% if not c.get('disabled') %}
          {% do ccd_list.append(c) %}
        {% endif %}
      {% endfor %}
    {% endif %}
    {% for d in ccds.ccd_dirs %}
{{ d.dir }}:
  file.directory:
    - user: {{ user }}
    - group: {{ group }}
    - mode: 0700
    - clean: True
      {% if ccd_list or ccds.ccd_default|default(False) %}
    - require:
        {% if ccds.ccd_default|default(False) %}
        - file: {{ d.dir }}/DEFAULT
        {% endif %}
        {% for c in ccd_list %}
        - file: {{ d.dir }}/{{ c.name }}
        {% endfor %}
      {% endif %}
    {% endfor %}
    {% for c in ccd_list %}
      {% for d in ccds.ccd_dirs %}
{{ d.dir }}/{{ c.name }}:
  file.managed:
    - source: salt://common/etc/openvpn/ccds/config
    - user: {{ user }}
    - group: {{ group }}
    - mode: 0400
    - template: jinja
    - defaults:
        loc: {{ c.name }}
        s: {{ c.attrs }}
        proto: {{ d.proto }}
      {% endfor %}
    {% endfor %}
  {% endif %}
{% endfor %}

{% if grains['os'] == "Gentoo" %}
/etc/sudoers.d/openvpn:
  {% if openvpn.get('openvpn_has_server') %}
  file.managed:
    - source: salt://common/etc/sudoers.d/openvpn
    - mode: 0440
    - user: root
    - group: root
  {% else %}
  file.absent
  {% endif %}
{% endif %}

{% for f in openvpn.get('openvpn_services', ()) %}
service.{{ f.name }}:
  {% if f.get('enabled') %}
  service.running:
    - enable: True
    {% if f.sig is defined %}
    - sig: {{ f.sig }}
    {% endif %}
  {% else %}
  service.disabled:
  {% endif %}
    - name: {{ f.name }}
{% endfor %}
