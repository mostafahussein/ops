{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/svscan.yaml" as svscan with context %}

service.svscan:
  pkg.installed:
    - name: {{ pkgs.svscan }}
    - refresh: False
  service.running:
    - name: svscan
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/bin/svscan /service"
{% elif grains['os'] == "Ubuntu" %}
    - sig: "/bin/sh /usr/bin/svscanboot"
{% endif %}

{% if svscan.services is defined %}
  {% for s in svscan.get('services', ()) %}
service.{{ s.name }}:
    {% if s.removed is defined %}
  service.dead:
    - provider: daemontools
    - name: {{ s.name }}
  file.absent:
      {% if grains['os'] == "Gentoo" %}
    - name: /service/{{ s.name }}/run
      {% elif grains['os'] == "Ubuntu" %}
    - name: /etc/service/{{ s.name }}/run
      {% endif %}
# module.wait:
#   - name: daemontools.missing
#   - m_name: {{ s.name }}
#   - watch:
#     - file:  service.{{ s.name }}
    {% else %}
  service.running:
      {% if s.sig is defined %}
    - sig: {{ s.sig }}
      {% endif %}
    - available: True
    - provider: daemontools
    - name: {{ s.name }}
    - watch:
      - file: service.{{ s.name }}
      {% if s.sources is defined and s.sources is iterable %}
        {% for sc in s.sources %}
      - file: {{ sc.name }}
        {% endfor %}
      {% endif %}
  file.managed:
      {% if grains['os'] == "Gentoo" %}
    - name: /service/{{ s.name }}/run
      {% elif grains['os'] == "Ubuntu" %}
    - name: /etc/service/{{ s.name }}/run
      {% endif %}
    - user: root
    - group: root
    - mode: 0755
    - source: {{ s.source_run }}
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
