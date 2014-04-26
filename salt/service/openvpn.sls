{% import_yaml "config/openvpn.yaml" as openvpn with context %}

/etc/openvpn:
  file.recurse:
    - source: salt://etc/openvpn/common
    - exclude_pat: .svn
    - include_empty: True
    - dir_mode: '0755'
    - file_mode: '0400'
    - user: openvpn
    - group: openvpn

{% for f in openvpn.get('openvpn_symlinks', ()) %}
{{ f.name }}:
  file.symlink:
    - target: {{ f.target }}
{% endfor %}

{% for f in openvpn.get('openvpn_scripts', ()) %}
{{ f.name }}:
  {% if f.get('disabled') %}
  file.absent
  {% else %}
  file.managed:
    - source: {{ f.source }}
    - mode: '0500'
    {% if grains['os'] == "Gentoo" %}
    - user: openvpn
    - group: openvpn
    {% elif grains['os'] == "Ubuntu" %}
    - user: root
    - group: root
    {% endif %}
    - template: jinja
    {% if f.location is defined %}
    - defaults:
       location: {{ f.location }}
    {% endif %}
  {% endif %}
{% endfor %}

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

{% for f in openvpn.get('openvpn_configs', ()) %}
{{ f.name }}:
  {% if f.get('enabled') %}
  file.managed:
    - source: {{ f.source }}
    - mode: 0400
    {% if grains['os'] == "Gentoo" %}
    - user: openvpn
    - group: openvpn
    {% elif grains['os'] == "Ubuntu" %}
    - user: root
    - group: root
    {% endif %}
    - template: jinja
    {% if f.location is defined %}
    - defaults:
       location: {{ f.location }}
    {% endif %}
  {% else %}
  file.absent
  {% endif %}
{% endfor %}

{% for f in openvpn.get('openvpn_ccds', ()) %}
  {% if f.type == "dir" %}
{{ f.name }}:
  file.directory:
    - user: openvpn
    - group: openvpn
    - mode: 0700
  {% elif f.type == "file" %}
{{ f.name }}:
  file.managed:
    - source: {{ f.source }}
    - user: {{ f.user | default('openvpn') }}
    - group: {{ f.group | default('openvpn') }}
    - mode: {{ f.mode | default('0400') }}
    - template: jinja
  {% elif f.type == "list" %}
    {% import_yaml f.name as ccds with context -%}
    {% for d in ccds.ccd_dirs %}
{{ d.dir }}:
  file.directory:
    - user: openvpn
    - group: openvpn
    - mode: 0700
    {% endfor %}
    {% if ccds.configs is defined %}
      {% for c in ccds.configs %}
        {% for d in ccds.ccd_dirs %}
{{ d.dir }}/{{ c.name }}:
          {% if c.get('disabled') %}
  file.absent
          {% else %}
  file.managed:
    - source: salt://common/etc/openvpn/ccds/config
    - user: openvpn
    - group: openvpn
    - mode: 0400
    - template: jinja
    - defaults:
        s: {{ c.attrs }}
        proto: {{ d.proto }}
          {% endif %}
        {% endfor %}
      {% endfor %}
    {% endif %}
  {% endif %}
{% endfor %}

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
