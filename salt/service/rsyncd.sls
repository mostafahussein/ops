{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/rsyncd.yaml" as rsyncd with context %}

{% if grains['os'] == "Ubuntu" %}
/etc/default/rsync:
  file.managed:
    - source: salt://common/etc/default/rsync
    - mode: 644
    - user: root
    - group: root
{% elif grains['os'] == "CentOS" %}
/etc/init.d/rsyncd:
  file.managed:
    - source: salt://common/etc/init.d/rsyncd
    - mode: 755
    - user: root
    - group: root
/etc/xinetd.d/rsync:
  file.managed:
    - source: salt://common/etc/xinetd.d/rsync
    - mode: 644
    - user: root
    - group: root
{% endif %}

service.rsyncd:
  pkg.installed:
    - name: {{ pkgs.rsync | default('rsync') }}
    - refresh: False
  service.running:
{% if grains['os'] == "Ubuntu" %}
    - name: rsync
    - sig: "/usr/bin/rsync --no-detach --daemon"
{% else %}
    - name: rsyncd
    - sig: "/usr/bin/rsync --daemon"
{% endif %}
    - enable: True
    - watch:
      - file: service.rsyncd
{% if grains['os'] == "Ubuntu" %}
      - file: /etc/default/rsync
{% endif %}
  file.managed:
    - name: /etc/rsyncd.conf
    - source: salt://common/etc/rsyncd.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja

{% for module in pillar.get('rsync_secret', []) %}
{{ module.name }}:
  file.managed:
    - mode: 400
    - user: root
    - group: root
    - content: {{ module.content }}
{% endfor %}

{% if rsyncd.rsyncd_filters is defined and
    rsyncd.rsyncd_filters is iterable %}
  {% for f in rsyncd.rsyncd_filters %}
{{ f.name }}:
  file.managed:
    - source: {{ f.source }}
    - mode: 644
    - user: root
    - group: root
  {% endfor %}
{% endif %}
