service.mcelog:
{% if grains.get('virtual') != 'physical' or
  grains['cpu_model'].startswith("AMD") %}
  service.dead:
    - enable: False
{% else %}
  service.running:
    - enable: True
{% endif %}
    - sig: /usr/sbin/mcelog
    - name: mcelog
