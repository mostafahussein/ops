{% if grains['os'] == "Gentoo" %}

  {% import_yaml "config/portage.yaml" as portage with context %}

  {% for f in portage.confs %}
/etc/portage/{{ f.name }}:
  file.managed:
    - source: salt://common/etc/portage/{{ f.name }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    {% if f.attrs is defined %}
    - defaults:
        attrs: {{ f.attrs }}
    {% endif %}
  {% endfor %}

  {% for f in portage.repos_confs %}
/etc/portage/repos.conf/{{ f.name }}:
  file.managed:
    - source: salt://common/etc/portage/repos.conf/{{ f.name }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    {% if f.attrs is defined %}
    - defaults:
        attrs: {{ f.attrs }}
    {% endif %}
  {% endfor %}

{% endif %}
