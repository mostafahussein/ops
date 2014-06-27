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
    {% if f.location is defined %}
    - defaults:
       location: {{ f.location }}
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
    - source: {{ f.source }}
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
    {% for d in ccds.ccd_dirs %}
{{ d.dir }}:
  file.directory:
    - user: {{ user }}
    - group: {{ group }}
    - mode: 0700
    {% endfor %}
    {% if ccds.configs is defined %}
      {% for c in ccds.configs.get(ccds.config_key, ()) %}
        {% for d in ccds.ccd_dirs %}
{{ d.dir }}/{{ c.name }}:
          {% if c.get('disabled') %}
  file.absent
          {% else %}
  file.managed:
    - source: salt://common/etc/openvpn/ccds/config
    - user: {{ user }}
    - group: {{ group }}
    - mode: 0400
    - template: jinja
    - defaults:
        loc: {{ c.name | replace('-', '_') }}
        s: {{ c.attrs }}
        proto: {{ d.proto }}
          {% endif %}
        {% endfor %}
      {% endfor %}
    {% endif %}
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
    - sig: {{ f.sig }}
  {% else %}
  service.disabled:
  {% endif %}
    - name: {{ f.name }}
{% endfor %}
