{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/sudo.yaml" as sudo with context %}

/etc/sudoers:
  pkg.installed:
    - name: {{ pkgs.sudo | default('sudo') }}
    - refresh: False 
  file.managed:
    - source: salt://common/etc/sudoers.{{ grains['os'] | lower }}
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
