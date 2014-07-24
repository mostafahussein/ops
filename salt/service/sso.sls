{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/kerberos.yaml" as krb with context %}

# @todo /etc/krb5.INTRA.*, /etc/krb5.keytab, /etc/krb5.ldap

pkg.kerberos:
  pkg.installed:
    - name: {{ pkgs.kerberos }}
    - refresh: False

service.kdcd:
  service.running:
    - enable: True
    - name: mit-krb5kdc
    - sig: krb5kdc
    - watch:
      - file: service.kdcd
  file.managed:
    - name: /etc/krb5.conf
    - source: salt://common/etc/krb5.conf
    - mode: 0644
    - user: root
    - group: root
    - template: jinja

service.slapd:
  pkg.installed:
    - name: {{ pkgs.slapd | default('slapd') }}
    - refresh: False
  service.running:
    - name: slapd
    - enable: True
    - sig: "/usr/lib64/openldap/slapd"
    - watch:
      - file: /etc/conf.d/slapd
      - file: /etc/sasl2/slapd.conf
      - file: service.slapd
  file.managed:
    - name: /etc/openldap/slapd.conf
    - source: salt://etc/openldap/slapd.conf.{{ grains['id'] }}
    - mode: 0640
    - user: root
    - group: ldap

{% for schema in ("freeradius", "openssh-lpk_openldap") %}
/etc/openldap/schema/{{ schema }}.schema:
  file.managed:
    - source: salt://common/etc/openldap/schema/{{ schema }}.schema
    - mode: 0644
    - user: root
    - group: root
{% endfor %}

/etc/conf.d/slapd:
  file.managed:
    - source: salt://common/etc/conf.d/slapd
    - mode: 0644
    - user: root
    - group: root

/etc/sasl2/slapd.conf:
  file.managed:
    - source: salt://common/etc/sasl2/slapd.conf
    - mode: 0644
    - user: root
    - group: root

service.saslauthd:
  pkg.installed:
    - name: {{ pkgs.saslauthd | default('saslauthd') }}
    - refresh: False
  service.running:
    - name: saslauthd
    - enable: True
    - sig: "/usr/sbin/saslauthd"
    - watch:
      - file: service.saslauthd
  file.managed:
    - name: /etc/conf.d/saslauthd
    - source: salt://common/etc/conf.d/saslauthd
    - mode: 0644
    - user: root
    - group: root

/etc/conf.d/mit-krb5kdc:
  file.managed:
    - source: salt://common/etc/conf.d/mit-krb5kdc
    - mode: 0644
    - user: root
    - group: root

{% if krb.kadmind_enabled is defined %}
/var/lib/krb5kdc/kadm5.acl:
  file.managed:
    - source: salt://common/var/lib/krb5kdc/kadm5.acl
    - mode: 0644
    - user: root
    - group: root
    - template: jinja

service.kadmind:
  service.running:
    - enable: True
    - name: mit-krb5kadmind
    - sig: kadmind

service.spawn-fcgi.fcgiwrap:
  pkg.installed:
    - name: {{ pkgs.spawn_fcgi | default('spawn-fcgi') }}
    - refresh: False
  service.running:
    - name: spawn-fcgi.fcgiwrap
    - enable: True
    - sig: /usr/sbin/fcgiwrap
    - watch:
      - file: service.spawn-fcgi.fcgiwrap
  file.managed:
    - name: /etc/conf.d/spawn-fcgi.fcgiwrap
    - source: salt://common/etc/conf.d/spawn-fcgi.fcgiwrap.scms
    - mode: 0644
    - user: root
    - group: root
{% else %}
service.kadmind:
  service.dead:
    - enable: False

service.spawn-fcgi.fcgiwrap:
  service.dead:
    - enable: False
{% endif %}
