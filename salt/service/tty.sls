{% import_yaml "config/tty.yaml" as tty with context %}

{% if grains['os'] == "Ubuntu" %}

  {% for tty in tty.ttys %}
/etc/init/{{ tty.name }}.conf:
  file.managed:
    {% if tty.rs232 is defined %}
    - source: salt://common/etc/init/ttyS.conf
    {% else %}
    - source: salt://common/etc/init/tty.conf
    {% endif %}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        tty: {{ tty.name }}
    {% if tty.start is defined %}
        start: {{ tty.start }}
        stop: {{ tty.stop }}
    {% endif %}
    {% if tty.lxc is defined %}
        lxc: {{ tty.lxc }}
    {% endif %}
    {% if tty.noclear is defined %}
        noclear: {{ tty.noclear }}
    {% endif %}

/etc/init/{{ tty.name }}.override:
    {% if tty.manual is defined %}
  file.managed:
    - source: salt://common/etc/init/manual.override
    - mode: 644
    - user: root
    - group: root
    - template: jinja

service.{{ tty.name }}:
  module.run:
    - name: service.stop
    {% else %}
  file.absent

service.{{ tty.name }}:
  module.run:
    - name: service.start
    {% endif %}
    - m_name: {{ tty.name }}
  {% endfor %}

{% endif %}
