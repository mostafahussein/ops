{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/stunnel.yaml" as stunnel with context %}

{% if grains['os'] == "Ubuntu" %}
  {% set svc_name = 'stunnel4' %}
{% else %}
  {% set svc_name = 'stunnel' %}
{% endif %}

{% if grains['os'] in ("CentOS",) %}
/etc/init/stunnel.conf:
  file.managed:
    - source: salt://common/etc/init/stunnel.conf
    - user: root
    - group: root
    - mode: 0644
{% endif %}

{% set ssl_files = [] %}

{% if stunnel.ssl_configs|default(False) %}
  {% for k,v in stunnel.ssl_configs.iteritems() %}
    {% if v.file is defined and
      v.managed|default(True) and
      not v.file in ssl_files %}
      {% do ssl_files.append(v.file) %}
    {% endif %}
  {% endfor %}
{% endif %}

{% if stunnel.services is defined %}
  {% for name,info in stunnel.services.iteritems() %}
    {% for k,v in info.iteritems() %}
      {% if v.file is defined and
        v.managed|default(True) and
        not v.file in ssl_files %}
        {% do ssl_files.append(v.file) %}
      {% endif %}
    {% endfor %}
  {% endfor %}
{% endif %}

service.stunnel:
  pkg.installed:
    - name: {{ pkgs.stunnel | default('stunnel') }}
    - refresh: False
{% if stunnel.services is defined %}
  service.running:
    - enable: True
    - watch:
      - file: /etc/stunnel/stunnel.conf
  {% if grains['os'] == "Ubuntu" %}
      - file: /etc/default/stunnel4
  {% endif %}
  {% for f in ssl_files %}
      - file: {{ f }}
  {% endfor %}
  {% if grains['os'] in ("CentOS",) %}
    - require:
      - file: /etc/init/stunnel.conf
  {% endif %}
{% else %}
  service.dead:
    - enable: False
{% endif %}
    - name: {{ svc_name }}
    - sig: /usr/bin/{{ svc_name }}

/etc/stunnel/stunnel.conf:
{% if stunnel.services is defined %}
  file.managed:
    - source: salt://common/etc/stunnel/stunnel.conf
    - user: root
    - group: root
    - mode: 0644
    - template: jinja
{% else %}
  file.absent
{% endif %}

{% if grains['os'] == "Ubuntu" %}
/etc/default/stunnel4:
  file.managed:
    - source: salt://common/etc/default/stunnel4
    - user: root
    - group: root
    - mode: 0644
    - template: jinja
{% endif %}

{% if stunnel.services is defined %}
  {% for f in ssl_files %}
{{ f }}:
  file.managed:
    - source: salt:/{{ f }}
    - user: {{ svc_name }}
    - group: {{ svc_name }}
    - mode: 0440
  {% endfor %}

/etc/stunnel:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - clean: True
  {% if stunnel.stunnel_exclude is defined %}
    - exclude_pat: {{ stunnel.stunnel_exclude }}
  {% else %}
    {% if grains['os'] == "Gentoo" %}
    - exclude_pat: ".keep*"
    {% elif grains['os'] == "Ubuntu" %}
    - exclude_pat: "README"
    {% endif %}
  {% endif %}
    - require:
      - file: /etc/stunnel/stunnel.conf
  {% if grains['os'] == "Ubuntu" %}
      - file: /etc/default/stunnel4
  {% endif %}
  {% for f in ssl_files %}
      - file: {{ f }}
  {% endfor %}

{% endif %}
