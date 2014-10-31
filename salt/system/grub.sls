{% if grains['os'] == "CentOS" and
  grains['osmajorrelease'][0] in ("6",) %}
{% else %}

/etc/default/grub:
  file.managed:
    - source: salt://common/etc/default/grub.{{ grains['os'] | lower }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
  {% if salt['file.directory_exists']('/sys/firmware/efi/') %}
    - defaults:
        efi: True
  {% endif %}
{% endif %}
