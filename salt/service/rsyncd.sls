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
  {% if grains['osmajorrelease'][0] == "6" %}
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

{% for module in pillar.get('rsync_secret', {}).keys() %}
{{ module }}:
  file.managed:
    - mode: 400
    - user: root
    - group: root
    - contents_pillar: rsync_secret:{{ module }}
{% endfor %}

{% if rsyncd.filters is defined and rsyncd.filters is iterable %}
  {% for f in rsyncd.filters %}
{{ f.name }}:
    {% if f.source is not defined %}
  file.absent
    {% else %}
  file.managed:
    - source: {{ f.source }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    {% endif %}
  {% endfor %}
{% endif %}
