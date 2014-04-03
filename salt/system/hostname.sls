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
  module.wait:
    - name: service.restart
    - m_name: hostname
    - watch:
      - file: /etc/hostname

{% if grains['os'] == "Ubuntu" %}
/etc/mailname:
  file.managed:
    - source: salt://common/etc/mailname
    - mode: 644
    - user: root
    - group: root
    - template: jinja
{% endif %}
