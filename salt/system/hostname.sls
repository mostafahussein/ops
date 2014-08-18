{% set idname = grains['id'].split(".")[0] %}

hostname:
  file.managed:
{% if grains['os'] == "Gentoo" %}
    - name: /etc/conf.d/hostname
{% elif grains['os'] == "Ubuntu" %}
    - name: /etc/hostname
{% elif grains['os'] == "CentOS" %}
  {% if grains['osmajorrelease'][0] == "6" %}
    - name: /etc/sysconfig/network
  {% elif grains['osmajorrelease'][0] == "7" %}
    - name: /etc/hostname
  {% endif %}
{% endif %}
    - source: salt://common/etc/conf.d/hostname
    - mode: 644
    - user: root
    - group: root
    - template: jinja
{% if grains['os'] == "CentOS" %}
  cmd.wait:
    - name: hostname {{ idname }}
    - cwd: /
{% else %}
  module.wait:
    - name: service.restart
    - m_name: hostname
{% endif %}
    - watch:
      - file: hostname

{% if grains['os'] == "Ubuntu" %}
/etc/mailname:
  file.managed:
    - source: salt://common/etc/mailname
    - mode: 644
    - user: root
    - group: root
    - template: jinja
{% endif %}
