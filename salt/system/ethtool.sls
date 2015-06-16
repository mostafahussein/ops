{% import_yaml "config/ip.yaml" as ip with context %}
{% import_yaml "config/nics.yaml" as nics with context %}

{% set ip = ip.get(nics.vars.domain) %}
{% if grains['id'] in ip %}
  {% set ip = ip.get(grains['id']) %}
{% else %}
  {% set idname = grains['id'].split('.')[0] %}
  {% set ip = ip.get(idname) %}
{% endif %}

{% if grains.get('virtual') not in ('kvm', 'xen') %}

  {% set local_conf = ip.get('ethtool', {}) %}

  {% for n in ip.get('nics',()) %}
    {% if n.name not in ("lo",) and n.type.split('_')[0] in ("host",) %}
      {% set sduplex = 'Full' %}
      {% set sspeed = 1000 %}
      {% set slink = True %}
      {% if local_conf %}
        {% set local_nic_conf = local_conf.get(n.name, {}) %}
        {% set slink = local_nic_conf.get('link', slink) %}
        {% set sduplex = local_nic_conf.get('duplex', sduplex) %}
        {% set sspeed = local_nic_conf.get('speed', sspeed) %}
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
