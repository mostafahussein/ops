{% import_yaml "config/ip.yaml" as ip with context %}
{% import_yaml "config/ethtool.yaml" as ethtool with context %}

{% set idname = grains['id'].split('.')[0] %}

{% set duplex = ethtool.conf.duplex|default('Full') %}
{% set speed = ethtool.conf.speed %}

{% if grains.get('virtual') not in ('kvm', 'xen') %}
  {% for n in ip.nics.get(idname, ()) %}
    {% if n.name not in ("lo",) and n.type.split('_')[0] in ("host",) %}
      {% set settings = {} %}
      {% for l in salt['cmd.run'](' '.join(('ethtool', n.name))).splitlines() %}
        {% if ': ' in l %}
          {% set li = l.strip().split(': ') %}
          {% do settings.update({li[0]: li[1]})%}
        {% endif %}
      {% endfor %}
      {% set rduplex = settings["Duplex"] %}
      {% set rspeed = settings["Speed"].strip('Mb/s')|int %}
      {% if rspeed < speed or rduplex != duplex %}
ethtool.{{ n.name }}:
  cmd.run:
    - name: "echo 'setting of {{ n.name }} is {{ "(%s/%s)"|format(rspeed, rduplex) }}, mismatch w/ {{ "(%s/%s)"|format(speed, duplex) }}'"
      {% endif %}
    {% endif %}
  {% endfor %}
{% endif %}
