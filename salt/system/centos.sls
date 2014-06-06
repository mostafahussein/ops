{% if grains['os'] == "CentOS" %}

/etc/selinux/config:
  file.managed:
    - source: salt://common/etc/selinux/config
    - mode: 644
    - user: root
    - group: root
    - template: jinja

{% endif %}
