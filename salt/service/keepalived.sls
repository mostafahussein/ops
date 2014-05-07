{% import_yaml "common/config/packages.yaml" as pkgs with context %}

{% set idname = grains['id'].split(".")[0] %}

{% if pillar.get('keepalived_enabled') %}

  {% for t in ("master", "backup") %}
/etc/keepalived/{{ t }}.sh:
  file.managed:
    - source: salt://etc/keepalived/notify.sh
    - mode: 755
    - user: root
    - group: root
    - template: jinja
    - defaults:
    {% if t == "master" %}
        action: restart
    {% elif t == "backup" %}
        action: stop
    {% endif %}
  {% endfor %}

service.keepalived:
  pkg.installed:
    - name: {{ pkgs.keepalived | default('keepalived') }}
    - refresh: False
  service.running:
    - name: keepalived
    - enable: True
    - sig: /usr/sbin/keepalived
  file.managed:
    - name: /etc/keepalived/keepalived.conf
    - source: salt://etc/keepalived/keepalived.conf
    - mode: 0400
    - user: root
    - group: root
    - template: jinja
    - defaults:
        id: {{ idname[-1] }}
        router_id: {{ idname[0:-1] | upper }}
{% else %}
  {% for t in ("master", "backup") %}
/etc/keepalived/{{ t }}.sh:
  file.absent
  {% endfor %}
service.keepalived:
  service.dead:
    - enable: False
    - name: keepalived
    - sig: /usr/sbin/keepalived
{% endif %}
