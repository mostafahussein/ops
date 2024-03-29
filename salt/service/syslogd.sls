{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/syslogd.yaml" as syslogd with context %}

{% if grains['os'] == "Gentoo" %}
  {% set svc_conf = "/etc/conf.d/rsyslog" %}
{% elif grains['os'] == "Ubuntu" %}
  {% set svc_conf = "/etc/default/rsyslog" %}
pkg.rsyslog-relp:
  pkg.installed:
    - name: rsyslog-relp
    - refresh: False
{% elif grains['os'] == "CentOS" %}
  {% set svc_conf = "/etc/sysconfig/rsyslog" %}
{% endif %}

{{ svc_conf }}:
  file.managed:
    - source:
      - salt://common{{ svc_conf }}
    - mode: 0644
    - user: root
    - group: root
    - template: jinja

service.rsyslog:
  pkg.installed:
    - name: {{ pkgs.rsyslog | default('rsyslog') }}
    - refresh: False
  service.running:
    - name: rsyslog
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/sbin/rsyslogd"
{% elif grains['os'] == "Ubuntu" %}
  {% if grains['osrelease'] in ('14.04',) %}
    - sig: "rsyslogd"
  {% else %}
    - sig: "rsyslogd -c5"
  {% endif %}
{% elif grains['os'] == "CentOS" %}
    - sig: "/sbin/rsyslogd -i /var/run/syslogd.pid -c 5"
{% endif %}
    - watch:
{% for f in syslogd.get('syslogd_confs', ()) %}
      - file: {{ f.name }}
{% endfor %}
      - file: {{ svc_conf }}

{% for f in syslogd.get('syslogd_confs', ()) %}
{{ f.name }}:
  {% if f.source is defined %}
  file.managed:
    - source: {{ f.source }}
    - mode: {{ f.mode|default('0644') }}
    - user: root
    - group: root
    - template: jinja
  {% else %}
  file.absent
  {% endif %}
{% endfor %}

{% if syslogd.logrotate_confs is defined and
      syslogd.logrotate_confs is iterable %}
  {% for f in syslogd.get('logrotate_confs') %}
{{ f.name }}:
  file.managed:
    - source: {{ f.source }}
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
    {% if f.attrs is defined %}
    - defaults:
        attrs: {{ f.attrs }}
    {% endif %}
  {% endfor %}
{% endif %}

/etc/logrotate.conf:
  file.managed:
    - source:
      - salt://etc/logrotate.conf.{{ grains['os'] | lower }}
      - salt://common/etc/logrotate.conf.{{ grains['os'] | lower }}
    - mode: 0644
    - user: root
    - group: root
    - template: jinja

/etc/rsyslog.d:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - clean: True
{% if syslogd.rsyslog_d_exclude is defined %}
    - exclude_pat: {{ syslogd.rsyslog_d_exclude }}
{% else %}
  {% if grains['os'] == "Gentoo" %}
    - exclude_pat: ".keep*"
  {% endif %}
{% endif %}
    - require:
{% for f in syslogd.get('syslogd_confs', ()) %}
        - file: {{ f.name }}
{% endfor %}
