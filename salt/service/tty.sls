{% if grains['os'] == "Ubuntu" %}

  {% import_yaml "config/tty.yaml" as tty with context %}

  {% if tty is defined and tty is iterable %}

    {% for t in tty.ttys %}
/etc/init/{{ t.name }}.conf:
  file.managed:
      {% if t.rs232 is defined %}
    - source: salt://common/etc/init/ttyS.conf
      {% else %}
    - source: salt://common/etc/init/tty.conf
      {% endif %}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        tty: {{ t.name }}
      {% if t.start is defined %}
        start: {{ t.start }}
        stop: {{ t.stop }}
      {% endif %}
      {% if t.lxc is defined %}
        lxc: {{ t.lxc }}
      {% endif %}
      {% if t.noclear is defined %}
        noclear: {{ t.noclear }}
      {% endif %}

/etc/init/{{ t.name }}.override:
      {% if t.manual is defined %}
  file.managed:
    - source: salt://common/etc/init/manual.override
    - mode: 644
    - user: root
    - group: root
    - template: jinja

service.{{ t.name }}:
  module.wait:
    - name: service.stop
      {% else %}
  file.absent

service.{{ t.name }}:
  module.wait:
    - name: service.start
      {% endif %}
    - m_name: {{ t.name }}
    - watch:
      - file: /etc/init/{{ t.name }}.conf
      - file: /etc/init/{{ t.name }}.override
    {% endfor %}

  {% endif %}
{% endif %}
