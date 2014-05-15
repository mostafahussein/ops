{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/svscan.yaml" as svscan with context %}

{% if grains['os'] == "Gentoo" %}
{% set svscan_dir = "/service" %}
{% elif grains['os'] == "Ubuntu" %}
{% set svscan_dir = "/etc/service" %}
{% endif %}

service.svscan:
  pkg.installed:
    - name: {{ pkgs.svscan }}
    - refresh: False
  service.running:
    - name: svscan
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/bin/svscan {{ svscan_dir }}"
{% elif grains['os'] == "Ubuntu" %}
    - sig: "/bin/sh /usr/bin/svscanboot"
{% endif %}

{% if svscan.services is defined and svscan.services is iterable %}
  {% for s in svscan.get('services', ()) %}
service.{{ s.name }}:
    {% if s.removed is defined %}
  service.dead:
    - provider: daemontools
    - name: {{ s.name }}
  file.absent:
    - name: {{ svscan_dir }}/{{ s.name }}/run

{{ svscan_dir }}/{{ s.name }}:
  file.absent
    {% else %}
      {% if s.disabled is defined %}
  service.dead:
    - provider: daemontools
    - name: {{ s.name }}
      {% else %}
  service.running:
        {% if s.sig is defined %}
    - sig: {{ s.sig }}
        {% endif %}
    - available: True
    - provider: daemontools
    - name: {{ s.name }}
    - require:
      - file: service.{{ s.name }}
      - file: {{ svscan_dir }}/{{ s.name }}/down
    - watch:
      - file: service.{{ s.name }}
        {% if s.sources is defined and s.sources is iterable %}
          {% for sc in s.sources %}
      - file: {{ sc.name }}
          {% endfor %}
        {% endif %}
      {% endif %}
  file.managed:
    - name: {{ svscan_dir }}/{{ s.name }}/run
    - user: root
    - group: root
    - mode: 0755
    - source: {{ s.source_run }}
    - require:
      - file: {{ svscan_dir }}/{{ s.name }}

{{ svscan_dir }}/{{ s.name }}/down:
      {% if s.disabled is defined %}
  file.managed:
    - user: root
    - group: root
    - mode: 0644
      {% else %}
  file.absent
      {% endif %}

{{ svscan_dir }}/{{ s.name }}:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    {% endif %}

    {% if s.sources is defined and s.sources is iterable %}
      {% for sc in s.sources %}
{{ sc.name }}:
        {% if s.removed is defined %}
  file.absent
        {% else %}
  file.managed:
    - user: {{ sc.user | default("root") }}
    - group: {{ sc.group | default("root") }}
    - mode: {{ sc.mode | default("0644") }}
    - template: jinja
    - source: {{ sc.source }}
        {% endif %}
      {% endfor %}
    {% endif %}

  {% endfor %}
{% endif %}
