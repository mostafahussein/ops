{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/mongodb.yaml" as mongodb with context %}

pkg.mongodb:
  pkg.installed:
    - name: {{ pkgs.mongodb | default('mongodb') }}
    - refresh: False

{% for t in mongodb.get('mongodb_srvs', ()) %}
service.mongodb.{{ t.name }}:
  service.running:
    - name: {{ t.name }}
    - enable: True
  {% if grains['os'] == "Gentoo" %}
    - sig: "/usr/bin/mongod --port {{ t.port }}"
    - watch:
      - file: /etc/conf.d/{{ t.name }}
    {% if t.name != "mongodb" %}
      - file: /etc/init.d/{{ t.name }}
  file.symlink:
    - name: /etc/init.d/{{ t.name }}
    - user: root
    - group: root
    - target: mongodb
    {% endif %}

/etc/conf.d/{{ t.name }}:
  file.managed:
    - source: salt://common/etc/conf.d/mongodb
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        port: {{ t.port | default('27017') }}
        run: {{ t.run | default('/var/run/mongodb') }}
        data: {{ t.data }}
        options: {{ t.options | default('--journal') }}
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
