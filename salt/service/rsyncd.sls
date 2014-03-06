{% import_yaml "config/rsyncd.yaml" as rsyncd with context %}

service.rsyncd:
  service.running:
{% if grains['os'] == "Gentoo" %}
    - name: rsyncd
    - sig: "/usr/bin/rsync --daemon"
{% elif grains['os'] == "Ubuntu" %}
    - name: rsync
    - sig: "/usr/bin/rsync --no-detach --daemon"
{% endif %}
    - enable: True
    - watch:
      - file: service.rsyncd
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

{% if rsyncd.rsyncd_filters is defined %}
  {% for f in rsyncd.rsyncd_filters %}
{{ f.name }}:
  file.managed:
    - source: {{ f.source }}
    - mode: 644
    - user: root
    - group: root
  {% endfor %}
{% endif %}
