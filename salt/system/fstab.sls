/etc/fstab:
  file.managed:
    - source: salt://common/etc/fstab
    - mode: 644
    - user: root
    - group: root
    - template: jinja

/mnt/{{ grains['os'] | lower }}:
  file.directory:
{% if grains['os'] == "CentOS" %}
    - mode: 0555
{% else %}
    - mode: 0755
{% endif %}
    - user: root
    - group: root
