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

/etc/sudoers.d/wheel:
  file.managed:
    - source: salt://common/etc/sudoers.d/wheel
    - mode: 440
    - user: root
    - group: root
