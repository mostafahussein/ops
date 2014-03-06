{% import_yaml "config/uwsgi.yaml" as uwsgi with context %}

{% if uwsgi.uwsgi_apps is defined %}
  {% for s in uwsgi.get('uwsgi_apps', ()) %}
service.uwsgi.{{ s.name }}:
  service.running:
    - name: uwsgi.{{ s.name }}
    - enable: True
    - sig: "/run/uwsgi_{{ s.name }}/{{ s.name }}.sock"
    - watch:
      - file: service.uwsgi.{{ s.name }}
  file.managed:
    - name: /etc/conf.d/uwsgi.{{ s.name }}
    - source: salt://common/etc/conf.d/uwsgi
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        s: {{ s }}
  {% endfor %}
{% endif %}
