{% set idname = grains['id'].split('.')[0] %}

/etc/nsswitch.conf:
  file.managed:
    - source:
        - salt://etc/nsswitch.conf.{{ grains['id'] | lower }}
        - salt://etc/nsswitch.conf.{{ idname | lower }}
        - salt://common/etc/nsswitch.conf.{{ grains['os'] | lower }}
    - mode: 0644
    - user: root
    - group: root
    - template: jinja

{% if grains['os'] == "Gentoo" %}
/etc/pam.d/system-auth:
  file.managed:
    - source: salt://common/etc/pam.d/system-auth
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
{% elif grains['os'] == "Ubuntu" %}
/etc/pam.d/sshd:
  file.managed:
    - source: salt://common/etc/pam.d/sshd
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
{% endif %}
