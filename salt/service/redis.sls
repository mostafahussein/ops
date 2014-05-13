{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/redis.yaml" as redis with context %}

pkg.redis:
  pkg.installed:
    - name: {{ pkgs.redis | default('redis-server') }}
    - refresh: False

/etc/redis:
  file.directory:
    - mode: 755
    - user: root
    - group: root

/etc/init.d/redis.svc:
{% if redis.get('redis_srvs') %}
  file.managed:
  {% if grains['os'] == "Gentoo" %}
    - source: salt://common/etc/init.d/redis.svc.gentoo
  {% elif grains['os'] == "Ubuntu" %}
    - source: salt://common/etc/init.d/redis.svc.ubuntu
  {% endif %}
    - mode: 755
    - user: root
    - group: root

  {% for f in redis.get('redis_common', ()) %}
/etc/redis/{{ f }}:
  file.managed:
    - source: salt://etc/redis/{{ f }}
    - mode: 644
    - user: root
    - group: root
  {% endfor %}
{% else %}
  file.absent
{% endif %}

{% for t in redis.get('redis_srvs', ()) %}
  {% if t.removed is defined %}
service.redis.{{ t.name }}:
  service.dead:
    - name: redis.{{ t.name }}
    - enable: False
  file.absent:
    - name:  /etc/init.d/redis.{{ t.name }}

/etc/redis/{{ t.name }}.conf:
  file.absent

    {% if grains['os'] == "Gentoo" %}
/etc/conf.d/redis.{{ t.name }}:
  file.absent
    {% endif %}
  {% else %}
service.redis.{{ t.name }}:
  service.running:
    - name: redis.{{ t.name }}
    - enable: True
    {% if grains['os'] == "Gentoo" %}
    - sig: "/usr/sbin/redis-server /etc/redis/{{ t.name }}.conf"
    {% elif grains['os'] == "Ubuntu" %}
    - sig: "/usr/bin/redis-server /etc/redis/{{ t.name }}.conf"
    {% endif %}
    - watch:
      - file: service.redis.{{ t.name }}
      - file: /etc/redis/{{ t.name }}.conf
    {% for f in redis.get('redis_common', ()) %}
      - file: /etc/redis/{{ f }}
    {% endfor %}
    {% if grains['os'] == "Gentoo" %}
      - file: /etc/conf.d/redis.{{ t.name }}
    {% endif %}
    - require:
      - file: service.redis.{{ t.name }}
      - file: /etc/redis/{{ t.name }}.conf
    {% for f in redis.get('redis_common', ()) %}
      - file: /etc/redis/{{ f }}
    {% endfor %}
    {% if grains['os'] == "Gentoo" %}
      - file: /etc/conf.d/redis.{{ t.name }}
    {% endif %}
  file.symlink:
    - name: /etc/init.d/redis.{{ t.name }}
    - user: root
    - group: root
    - target: redis.svc

/etc/redis/{{ t.name }}.conf:
  file.managed:
    - source: salt://common/etc/redis/redis.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        name: {{ t.name }}
        attrs: {{ t.attrs }}

    {% if grains['os'] == "Gentoo" %}
/etc/conf.d/redis.{{ t.name }}:
  file.managed:
    - source: salt://common/etc/conf.d/redis.svc
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        redis_name: {{ t.name }}
        redis_dir: {{ t.attrs.dir }}
        redis_user: {{ t.attrs.user | default('redis') }}
        redis_group: {{ t.attrs.group | default('redis') }}
    {% endif %}
  {% endif %}
{% endfor %}
