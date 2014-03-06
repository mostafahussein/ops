{% import_yaml "config/mail.yaml" as mail with context %}

{% if mail.postfix_enabled is defined %}

service.postfix:
  service.running:
    - name: postfix
    - enable: True
    - sig: /usr/libexec/postfix/master

service.dovecot:
  service.running:
    - name: dovecot
    - enable: True
    - sig: "/usr/sbin/dovecot -c /etc/dovecot/dovecot.conf"

service.imapproxy:
  service.running:
    - name: imapproxy
    - enable: True
    - sig: "/usr/sbin/imapproxy"

# @todo imapproxy.conf

service.spamd:
  service.running:
    - name: spamd
    - enable: True
    - sig: "/usr/sbin/spamd -d"

service.memcached:
  service.running:
    - name: memcached
    - enable: True
    - sig: "/usr/bin/memcached -d -p 11211"

service.exim:
  service.disabled

#todo postfix config

{% else %}

service.postfix:
  service.disabled

service.dovecot:
  service.disabled

service.imapproxy:
  service.disabled

service.spamd:
  service.disabled

service.exim:
  service.running:
{% if grains['os'] == "Gentoo" %}
    - name: exim
{% elif grains['os'] == "Ubuntu" %}
    - name: exim4
{% endif %}
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/sbin/exim -C /etc/exim/exim.conf"
    - watch:
      - file: service.exim
  file.managed:
    - name: /etc/exim/exim.conf
    - source: salt://common/etc/exim/exim.conf
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
{% elif grains['os'] == "Ubuntu" %}
    - sig: "usr/sbin/exim4 -bd -q"
{% endif %}

{% endif %}
