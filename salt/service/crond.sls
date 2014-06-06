{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/crond.yaml" as crond with context %}

service.crond:
  pkg.installed:
    - name: {{ pkgs.cron | default('cron') }}
    - refresh: False
  service.running:
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - name: cronie
    - sig: crond
{% elif grains['os'] == "Ubuntu" %}
    - name: cron
    - sig: cron
{% elif grains['os'] == "CentOS" %}
    - name: crond
    - sig: crond
{% endif %}

/etc/crontab:
  file.managed:
    - source: salt://common/etc/crontab.{{ grains['os'] | lower }}
    - user: root
    - group: root
    - mode: 0644

{% if crond.crond_files is defined and
    crond.crond_files is iterable %}
  {% for f in crond.get("crond_files", ()) %}
{{ f.name }}:
    {% if f.removed is defined %}
  file.absent
    {% else %}
  file.managed:
    - source: {{ f.source }}
    - user: root
    - group: root
    - mode: 0644
    {% endif %}
  {% endfor %}
{% endif %}
