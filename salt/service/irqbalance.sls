{% if grains['os'] == "Ubuntu" %}
{% import_yaml "config/irqbalance.yaml" as irqbalance with context %}
service.irqbalance:
  {% if irqbalance.enabled is defined %}
  file.absent:
    - name: /etc/init/irqbalance.override
  service.running:
    - name: irqbalance
    - sig: /usr/sbin/irqbalance
  module.wait:
    - name: service.start
  {% else %}
  file.managed:
    - name: /etc/init/irqbalance.override
    - source: salt://common/etc/init/manual.override
    - mode: 644
    - user: root
    - group: root
    - template: jinja
  module.wait:
    - name: service.stop
  {% endif %}
    - m_name: irqbalance
    - watch:
      - file: service.irqbalance

  {% if irqbalance.enabled is defined %}
/etc/default/irqbalance:
  file.managed:
    - source: salt://common/etc/default/irqbalance
    - mode: 644
    - user: root
    - group: root
    - template: jinja
  {% endif %}
{% endif %}
