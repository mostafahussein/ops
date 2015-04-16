{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/mongodb.yaml" as mongodb with context %}

{% if mongodb %}

pkg.mongodb:
  pkg.installed:
    - name: {{ pkgs.mongodb | default('mongodb') }}
    - refresh: False

{% else %}

  {% set mongodb = {} %}

#pkg.mongodb:
#  pkg.removed:
#    - name: {{ pkgs.mongodb | default('mongodb') }}

{% endif %}

{% for t in mongodb.get('mongodb_srvs', ()) %}
service.mongodb.{{ t.name }}:
  service.running:
    - name: {{ t.name }}
    - enable: True
  {% if grains['os'] == "Gentoo" %}
    - sig: "/usr/bin/mongod --config /etc/{{ t.name }}.conf"
    - watch:
      - file: /etc/{{ t.name }}.conf
    {% if t.name != "mongodb" %}
      - file: /etc/init.d/{{ t.name }}
  file.symlink:
    - name: /etc/init.d/{{ t.name }}
    - user: root
    - group: root
    - target: mongodb
    {% endif %}

/etc/conf.d/{{ t.name }}:
  file.absent

/etc/{{ t.name }}.conf:
  file.managed:
    - source: salt://common/etc/mongodb.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        name: {{ t.name }}
        bindIp: {{ t.bindIp|default('0.0.0.0') }}
        port: {{ t.port | default('27017') }}
        run: {{ t.run | default('/var/run/mongodb') }}
        data: {{ t.data }}
    {% if t.replset is defined %}
        replset: {{ t.replset }}
    {% endif %}
  {% endif %}
{% endfor %}

{% for f in mongodb.get('mongodb_dirs', ()) %}
{{ f.name }}:
  file.directory:
    - makedirs: True
    - user: {{ f.user | default('mongodb') }}
    - group: {{ f.group | default('mongodb') }}
    - mode: {{ f.mode | default('0755') }}
{% endfor %}
