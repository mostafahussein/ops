{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/apache.yaml" as apache with context %}

service.apache2:
  pkg.installed:
    - name: {{ pkgs.apache }}
    - refresh: False
  service.running:
    - name: apache2
    - enable: True
    - sig: "/usr/sbin/apache2 -D"
    - watch:
      - file: /etc/conf.d/apache2
{% for f in apache.get('apache_confs', ()) %}
      - file: {{ f.name }}
{% endfor %}

/etc/conf.d/apache2:
  file.managed:
    - source: salt://common/etc/conf.d/apache2
    - mode: 0644
    - user: root
    - group: root

{% for f in apache.get('apache_confs', ()) %}
{{ f.name }}:
  file.managed:
  {% if f.target is defined %}
    - source: {{ f.target }}
  {% else %}
    - source: salt:/{{ f.name }}
  {% endif %}
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
{% endfor %}
