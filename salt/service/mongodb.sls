{% import_yaml "config/mongodb.yaml" as mongodb with context %}

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
