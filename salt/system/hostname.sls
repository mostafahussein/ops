/etc/hostname:
  file.managed:
{% if grains['os'] == "Gentoo" %}
    - name: /etc/conf.d/hostname
{% endif %}
    - source: salt://common/etc/conf.d/hostname
    - mode: 644
    - user: root
    - group: root
    - template: jinja
