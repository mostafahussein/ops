{% for f in ("hosts", "networks") %}
/etc/{{ f }}:
  file.managed:
    - source:
      - salt://etc/{{ f }}.{{ grains['os'] | lower }}
      - salt://common/etc/{{ f }}.{{ grains['os'] | lower }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
{% endfor %}
