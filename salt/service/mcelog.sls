service.mcelog:
{% if grains['cpu_model'].startswith("AMD") %}
  service.disabled:
{% else %}
  service.running:
    - enable: True
    - sig: /usr/sbin/mcelog
{% endif %}
    - name: mcelog
