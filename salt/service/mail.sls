{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/mail.yaml" as mail with context %}

{% if mail.postfix_enabled is defined %}

service.postfix:
  pkg.installed:
    - name: {{ pkgs.postfix | default("postfix") }}
    - refresh: False
  service.running:
    - name: postfix
    - enable: True
    - sig: /usr/libexec/postfix/master

service.dovecot:
  pkg.installed:
    - name: {{ pkgs.dovecot | default("dovecot") }}
    - refresh: False
  service.running:
    - name: dovecot
    - enable: True
    - sig: "/usr/sbin/dovecot -c /etc/dovecot/dovecot.conf"

service.imapproxy:
  pkg.installed:
    - name: {{ pkgs.imapproxy | default("imapproxy") }}
    - refresh: False
  service.running:
    - name: imapproxy
    - enable: True
    - sig: "/usr/sbin/imapproxy"

# @todo imapproxy.conf

service.spamd:
  pkg.installed:
    - name: {{ pkgs.spamd | default("spamd") }}
    - refresh: False
  service.running:
    - name: spamd
    - enable: True
    - sig: "/usr/sbin/spamd -d"

service.memcached:
  pkg.installed:
    - name: {{ pkgs.memcached | default("memcached") }}
    - refresh: False
  service.running:
    - name: memcached
    - enable: True
    - sig: "/usr/bin/memcached -d -p 11211"

service.exim:
  service.dead:
    - enable: False

#todo postfix config

{% else %}

service.postfix:
  service.dead:
    - enable: False

service.dovecot:
  service.dead:
    - enable: False

service.imapproxy:
  service.dead:
    - enable: False

service.spamd:
  service.dead:
    - enable: False

service.exim:
  pkg.installed:
    - name: {{ pkgs.exim | default("exim4") }}
    - refresh: False
  service.running:
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - name: exim
    - sig: "/usr/sbin/exim -C /etc/exim/exim.conf"
{% elif grains['os'] == "Ubuntu" %}
    - name: exim4
    - sig: "usr/sbin/exim4 -bd -q"
{% endif %}
{% if mail.exim_configs is defined %}
    - watch:
  {% for f in mail.exim_configs %}
      - file: {{ f.name }}
  {% endfor %}
{% endif %}

{% if mail.exim_configs is defined %}
  {% for f in mail.exim_configs %}
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
{% endif %}

{% endif %}
