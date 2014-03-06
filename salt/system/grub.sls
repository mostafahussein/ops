/etc/default/grub:
  file.managed:
{% if grains['os'] == "Gentoo" %}
    - source: salt://common/etc/default/grub.gentoo
{% elif grains['os'] == "Ubuntu" %}
    - source: salt://common/etc/default/grub.ubuntu
{% endif %}
    - mode: 644
    - user: root
    - group: root
