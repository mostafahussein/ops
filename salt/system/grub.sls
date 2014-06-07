{% if grains['os'] == "CentOS" and
  grains['osmajorrelease'][0] <= "6" %}
{% else %}

/etc/default/grub:
  file.managed:
    - source: salt://common/etc/default/grub.gentoo.{{ grains['os'] | lower }}
    - mode: 644
    - user: root
    - group: root

{% endif %}
