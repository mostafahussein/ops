{% import_yaml "config/redis.yaml" as redis with context %}

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
  {% for f in redis.get('redis_common', ()) %}
      - file: /etc/redis/{{ f }}
  {% endfor %}
      - file: /etc/redis/{{ t.name }}.conf
  file.symlink:
    - name: /etc/init.d/redis.{{ t.name }}
    - user: root
    - group: root
    - target: redis.svc

/etc/redis/{{ t.name }}.conf:
  file.managed:
  {% if t.conf is defined %}
    - source: salt://etc/redis/{{ t.conf }}
  {% else %}
    - source: salt://etc/redis/{{ t.name }}.conf
  {% endif %}
    - mode: 644
    - user: root
    - group: root
    - template: jinja

  {% if grains['os'] == "Gentoo" %}
/etc/conf.d/redis.{{ t.name }}:
  file.managed:
    - source: salt://etc/conf.d/redis.svc
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        redis_name: {{ t.name }}
        redis_dir: {{ t.dir }}
        redis_group: {{ t.group | default('redis') }}
  {% endif %}
{% endfor %}
