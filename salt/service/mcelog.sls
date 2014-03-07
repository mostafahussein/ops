service.mcelog:
{% if grains.get('virtual') != 'physics' or
  grains['cpu_model'].startswith("AMD") %}
  service.disabled:
{% else %}
  service.running:
    - enable: True
    - sig: /usr/sbin/mcelog
{% endif %}
    - name: mcelog
