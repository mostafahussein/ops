{% import_yaml "config/ip.yaml" as ip with context %}
{% import_yaml "config/ethtool.yaml" as ethtool with context %}

{% set idname = grains['id'].split('.')[0] %}

{% if grains.get('virtual') not in ('kvm', 'xen') %}

  {% set duplex = ethtool.conf.duplex|default('Full') %}
  {% set speed = ethtool.conf.speed %}

  {% for n in ip.get(idname, {}).get('nics',()) %}
    {% if n.name not in ("lo",) and n.type.split('_')[0] in ("host",) %}
      {% set sduplex = duplex %}
      {% set sspeed = speed %}
      {% set slink = True %}
      {% set local_conf = ethtool.conf.get('local') %}
      {% if local_conf %}
      {% set local_nic_conf = local_conf.get(n.name, {}) %}
        {% set slink = local_nic_conf.get('link', True) %}
        {% if local_nic_conf.get('duplex') %}
          {% set sduplex = local_nic_conf.get('duplex') %}
        {% endif %}
        {% if local_nic_conf.get('speed') %}
          {% set sspeed = local_nic_conf.get('speed') %}
        {% endif %}
      {% endif %}
      {% set settings = {} %}
      {% for l in salt['cmd.run'](' '.join(('ethtool', n.name))).splitlines() %}
        {% if ': ' in l %}
          {% set li = l.strip().split(': ') %}
          {% do settings.update({li[0]: li[1]})%}
        {% endif %}
      {% endfor %}
      {% set rduplex = settings["Duplex"] %}
      {% set rspeed = settings["Speed"].strip('Mb/s')|int %}
      {% set rlink = settings["Link detected"] %}
      {% if rlink == "no" %}
        {% if slink %}
ethtool.{{ n.name }}:
  cmd.run:
    - name: "echo 'link of {{ n.name }} is {{ rlink }}.'"
        {% endif %}
      {% elif rspeed < sspeed or rduplex != sduplex %}
ethtool.{{ n.name }}:
  cmd.run:
    - name: "echo 'setting of {{ n.name }} is {{ "(%s/%s)"|format(rspeed, rduplex) }}, mismatch w/ {{ "(%s/%s)"|format(sspeed, sduplex) }}'"
      {% endif %}
    {% endif %}
  {% endfor %}
{% endif %}
