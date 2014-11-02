{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/mail.yaml" as mail with context %}

{% if 'postfix' in mail.services|default(()) %}

  {% import_yaml "config/postfix.yaml" as postfix with context %}

  {% set postfix_files = [] %}
  {% for f in postfix.postfix_confs %}
    {% do postfix_files.append(f.name) %}
{{ f.name }}:
  file.managed:
    - source:
      - salt://common/{{ f.name }}
      - salt:/{{ f.name }}
    - mode: {{ f.mode|default('0644') }}
    - user: root
    - group: root
    - template: jinja
  {% endfor %}

service.postfix:
  pkg.installed:
    - name: {{ pkgs.postfix | default("postfix") }}
    - refresh: False
  service.running:
    - name: postfix
    - enable: True
    - sig: /usr/libexec/postfix/master
  {% if postfix_files %}
    - watch:
    {% for f in postfix_files %}
        - file: {{ f }}
    {% endfor %}
  {% endif %}

{% else %}

service.postfix:
  service.dead:
    - name: postfix
    - enable: False

{% endif %}

{% if 'dovecot' in mail.services|default(()) %}
  {% import_yaml "config/dovecot.yaml" as dovecot with context %}

  {% set dovecot_files = [] %}
  {% for f in dovecot.dovecot_confs %}
    {% do dovecot_files.append(f.name) %}
{{ f.name }}:
  file.managed:
    - source:
      - salt://common/{{ f.name }}
      - salt:/{{ f.name }}
    - mode: {{ f.mode|default('0644') }}
    - user: root
    - group: root
    - template: jinja
  {% endfor %}

service.dovecot:
  pkg.installed:
    - name: {{ pkgs.dovecot | default("dovecot") }}
    - refresh: False
  service.running:
    - name: dovecot
    - enable: True
    - sig: "/usr/sbin/dovecot -c /etc/dovecot/dovecot.conf"
  {% if dovecot_files %}
    - watch:
    {% for f in dovecot_files %}
        - file: {{ f }}
    {% endfor %}
  {% endif %}

{% else %}

service.dovecot:
  service.dead:
    - name: dovecot
    - enable: False

{% endif %}

{% if 'exim' in mail.services|default(()) %}

  {% import_yaml "config/exim.yaml" as exim with context %}

  {% set exim_files = [] %}
  {% for f in exim.exim_confs|default(()) %}
    {% do exim_files.append(f.name) %}
{{ f.name }}:
  file.managed:
    - source:
      {% if f.source is defined %}
      - salt:/{{ f.source }}
      - salt://common{{ f.source }}
      {% else %}
      - salt:/{{ f.name }}
      - salt://common{{ f.name }}
      {% endif %}
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
  {% endfor %}

service.exim:
  pkg.installed:
    - name: {{ pkgs.exim | default("exim") }}
    - refresh: False
  service.running:
    - enable: True
  {% if grains['os'] == "Gentoo" %}
    - name: exim
    - sig: "/usr/sbin/exim -C /etc/exim/exim.conf"
  {% elif grains['os'] == "Ubuntu" %}
    - name: exim4
    - sig: "usr/sbin/exim4 -bd -q"
  {% elif grains['os'] == "CentOS" %}
    - name: exim
    - sig: "/usr/sbin/exim -bd -q1h"
  {% endif %}
  {% if exim_files %}
    - watch:
    {% for f in exim_files %}
      - file: {{ f }}
    {% endfor %}
  {% endif %}

{% else %}

service.exim:
  service.dead:
    - enable: False

{% endif %}

{% if 'imapproxy' in mail.services|default(()) %}

/etc/imapproxy.conf:
  file.managed:
    - source:
      - salt://etc/imapproxy.conf
    - mode: 0644
    - user: root
    - group: root
    - template: jinja

service.imapproxy:
  pkg.installed:
    - name: {{ pkgs.imapproxy | default("imapproxy") }}
    - refresh: False
  service.running:
    - name: imapproxy
    - enable: True
    - sig: "/usr/sbin/imapproxy"
    - watch:
        - file: /etc/imapproxy.conf

{% else %}

service.imapproxy:
  service.dead:
    - name: imapproxy
    - enable: False

{% endif %}

{% if 'spamd' in mail.services|default(()) %}

  {% import_yaml "config/spamd.yaml" as spamd with context %}

  {% set spamd_files = [] %}
  {% for f in spamd.spamd_confs|default(()) %}
    {% do spamd_files.append(f.name) %}
{{ f.name }}:
  file.managed:
    - source:
      - salt:/{{ f.name }}
      - salt://common{{ f.name }}
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
  {% endfor %}
service.spamd:
  pkg.installed:
    - name: {{ pkgs.spamd | default("spamd") }}
    - refresh: False
  service.running:
    - name: spamd
    - enable: True
    - sig: "/usr/sbin/spamd -d"
  {% if spamd_files %}
    - watch:
    {% for f in spamd_files %}
      - file: {{ f }}
    {% endfor %}
  {% endif %}

{% else %}

service.spamd:
  service.dead:
    - name: spamd
    - enable: False

{% endif %}
