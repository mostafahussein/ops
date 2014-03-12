{% if grains['os'] == "Gentoo" %}
/etc/pam.d/system-auth:
  file.managed:
    - source: salt://common/etc/pam.d/system-auth
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
{% endif %}
