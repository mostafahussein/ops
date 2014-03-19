{% import_yaml "config/syslogd.yaml" as syslogd with context %}

service.rsyslog:
  service.running:
    - name: rsyslog
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/sbin/rsyslogd"
{% elif grains['os'] == "Ubuntu" %}
    - sig: "rsyslogd -c5"
{% endif %}
    - watch:
{% for f in syslogd.get('syslogd_confs', ()) %}
      - file: {{ f.name }}
{% endfor %}

{% for f in syslogd.get('syslogd_confs', ()) %}
{{ f.name }}:
  file.managed:
    - source: {{ f.target }}
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
{% endfor %}

{% if syslogd.get('is_syslog_server') %}
/etc/logrotate.d/local-rsyslog:
  file.managed:
    - source: salt://etc/logrotate.d/rsyslog
    - mode: 0644
    - user: root
    - group: root
{% endif %}

/etc/logrotate.conf:
  file.managed:
    - source:
      - salt://etc/logrotate.conf.{{ grains['os'] | lower }}
      - salt://common/etc/logrotate.conf.{{ grains['os'] | lower }}
    - mode: 0644
    - user: root
    - group: root
