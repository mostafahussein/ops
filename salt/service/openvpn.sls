{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/openvpn.yaml" as openvpn with context %}

{% if grains['os'] == "Gentoo" %}
{% set user = "root" %}
{% set group = "openvpn" %}
{% else %}
{% set user = "root" %}
{% set group = "root" %}
{% endif %}

pkg.openvpn:
  pkg.installed:
    - name: {{ pkgs.openvpn | default('openvpn') }}
    - refresh: False

{% set vpn_requires = [] %}

{% for f in openvpn.get('openvpn_scripts', ()) %}
{{ f.name }}:
  {% if f.get('disabled') %}
  file.absent
  {% else %}
  file.managed:
    - source: {{ f.source }}
    - mode: '0550'
    - user: {{ user }}
    - group: {{ group }}
    - template: jinja
    {% if f.location is defined %}
    - defaults:
       location: {{ f.location }}
    {% endif %}
  {% endif %}

  {% do vpn_requires.append(f.name) %}

{% endfor %}


{% for f in openvpn.get('openvpn_configs', ()) %}
{{ f.name }}:
  {% if f.get('enabled') %}
  file.managed:
    - source: {{ f.source }}
    - mode: 0440
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

    {% do vpn_requires.append(f.name) %}

  {% else %}
  file.absent
  {% endif %}
{% endfor %}

{% for f in openvpn.get('openvpn_files', ()) %}
  {% if f.type == "dir" %}
    {% do vpn_requires.append(f.name) %}
{{ f.name }}:
  file.directory:
    - user: {{ user }}
    - group: {{ group }}
    - dir_mode: {{ f.dir_mode|default('0550') }}
    - file_mode: {{ f.file_mode|default('0440') }}
    - recurse:
        - user
        - group
        - mode
  {% elif f.type == "file" %}
    {% do vpn_requires.append(f.name) %}
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
    - mode: {{ f.mode | default('0440') }}
    - template: jinja
  {% elif f.type == "symlink" %}
    {% do vpn_requires.append(f.name) %}
{{ f.name }}:
  file.symlink:
    - user: {{ f.user|default(user) }}
    - group: {{ f.group|default(group) }}
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
      {% do vpn_requires.append(d.dir) %}
{{ d.dir }}:
  file.directory:
    - user: {{ user }}
    - group: {{ group }}
    - mode: 0550
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
    - mode: 0440
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

/etc/openvpn:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - clean: True
{% if grains['os'] in ('Gentoo',) %}
    - exclude_pat: "E@^(\\.keep_net-misc_openvpn-0|(up|down)\\.sh)$"
{% elif grains['os'] in ('Ubuntu',) %}
    - exclude_pat: "update-resolv-conf"
{% endif %}
    - require:
{% for f in vpn_requires %}
      - file: {{ f }}
{% endfor %}
