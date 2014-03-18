{% import_yaml "config/sudo.yaml" as sudo with context %}

/etc/sudoers:
  file.managed:
{% if grains['os'] == "Gentoo" %}
    - source: salt://common/etc/sudoers.gentoo
{% elif grains['os'] == "Ubuntu" %}
    - source: salt://common/etc/sudoers.ubuntu
{% endif %}
    - mode: 440
    - user: root
    - group: root

{% if sudo.files is defined and sudo.files is iterable %}
  {% for f in sudo.files %}
/etc/sudoers.d/{{ f.name }}:
  file.managed:
    - source: {{ f.source }}
    - mode: 440
    - user: root
    - group: root
    - template: jinja
  {% endfor %}
{% endif %}
