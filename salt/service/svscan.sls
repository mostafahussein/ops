{% import_yaml "config/svscan.yaml" as svscan with context %}

service.svscan:
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
  service.running:
    {% if s.sig is defined %}
    - sig: {{ s.sig}}
    {% endif %}
    - available: True
    - provider: daemontools
    - name: {{ s.name}}
    - watch:
      - file: service.{{ s.name }}
  file.managed:
    {% if grains['os'] == "Gentoo" %}
    - name: /service/{{ s.name }}/run
    {% elif grains['os'] == "Ubuntu" %}
    - name: /etc/service/{{ s.name }}/run
    {% endif %}
    - user: root
    - group: root
    - mode: 0755
    - source: {{ s.source}}
  {% endfor %}
{% endif %}
