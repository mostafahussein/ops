{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/uwsgi.yaml" as uwsgi with context %}

{% if uwsgi.uwsgi_apps is defined %}
pkg.uwsgi:
  pkg.installed:
    - name: {{ pkgs.uwsgi | default('uwsgi') }}
    - refresh: False

  {% for s in uwsgi.get('uwsgi_apps', ()) %}
service.uwsgi.{{ s.name }}:
  service.running:
    - name: uwsgi.{{ s.name }}
    - enable: True
    - sig: "\"\\-\\-pidfile /var/run/uwsgi_{{ s.name }}/{{ s.name }}.pid\""
    - watch:
      - file: service.uwsgi.{{ s.name }}
      - file: /etc/init.d/uwsgi.{{ s.name }}
  file.managed:
    - name: /etc/conf.d/uwsgi.{{ s.name }}
    - source: salt://common/etc/conf.d/uwsgi
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        s: {{ s }}

/etc/init.d/uwsgi.{{ s.name }}:
  file.symlink:
    - user: root
    - group: root
    - target: uwsgi
  {% endfor %}
{% endif %}
