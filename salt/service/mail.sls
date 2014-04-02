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
  service.running:
    - enable: True
    - watch:
      - file: service.exim
{% if grains['os'] == "Gentoo" %}
    - name: exim
    - sig: "/usr/sbin/exim -C /etc/exim/exim.conf"
  file.managed:
    - name: /etc/exim/exim.conf
    - source: salt://common/etc/exim/exim.conf
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
{% elif grains['os'] == "Ubuntu" %}
    - name: exim4
    - sig: "usr/sbin/exim4 -bd -q"
  file.managed:
    - name: /etc/exim4/update-exim4.conf.conf
    - source: salt://common/etc/exim/update-exim4.conf.conf
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
{% endif %}

{% endif %}
