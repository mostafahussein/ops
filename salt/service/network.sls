{# @todo add strictly ipv6 check, complete match #}

{% import_yaml "config/nics.yaml" as nics with context %}
{% import_yaml "config/ip.yaml" as ip with context %}
{% set idname = grains['id'].split(".")[0] %}

{% if grains['os'] == "Gentoo" %}

/etc/conf.d/net:
  file.managed:
    - source:
  {% if nics is defined and nics.netconf is defined %}
      - {{ nics.netconf }}
  {% endif %}
      - salt://etc/conf.d/net.{{ grains['id'] }}
      - salt://etc/conf.d/net.{{ grains['id'].split(".")[0] }}
    - mode: 0644
    - user: root
    - group: root
    - template: jinja

  {% for i in nics.get('nics', []) %}
service.net.{{ i }}:
  service.enabled:
    - name: net.{{ i }}
  file.symlink:
    - name: /etc/init.d/net.{{ i }}
    - target: net.lo
  {% endfor %}

{% elif grains["os"] == "Ubuntu" %}

/etc/network/interfaces:
  file.managed:
    - source:
  {% if nics is defined and nics.netconf is defined %}
      - {{ nics.netconf }}
  {% endif %}
      - salt://etc/network/interfaces.{{ grains['id'] }}
      - salt://etc/network/interfaces.{{ grains['id'].split(".")[0] }}
    - mode: 0644
    - user: root
    - group: root
    - template: jinja

{% endif %}

{% if grains['os'] == "Ubuntu" %}

{% if ip.nics is defined %}
  {% set ip_seted = {} %}
  {% set ip_seted6 = {} %}
  {% for l in ip.nics.get(idname, ()) %}{%- if l.type.split('_')[0] == 'host' -%}
    {% set iface = l.name.split(":")[0] %}
    {% if iface not in ip_seted %}
      {% do ip_seted.update({iface:[]}) %}
    {% endif %}
    {% if iface not in ip_seted6 %}
      {% do ip_seted6.update({iface:[]}) %}
    {% endif %}
    {% for i in l.ip %}
      {% if i.family | default("inet") == "inet6" %}
        {% do ip_seted6[iface].append(i.addr) %}
      {% else %}
        {% do ip_seted[iface].append(i.addr) %}
      {% endif %}
    {% endfor %}
  {% endif %}{% endfor %}
  {% for k in ip_seted %}
    {% set x = ip_seted[k]|sort %}
    {% do ip_seted.update({k:x}) %}
  {% endfor %}
  {% for k in ip_seted6 %}
    {% set x = ip_seted6[k]|sort %}
    {% do ip_seted6.update({k:x}) %}
  {% endfor %}

  {% for iface in ip_seted %}
    {% set ip_real = ""|list %}
    {% set ip_real6 = ""|list %}
    {# for ipv4 #}
    {% for k,v in salt['network.interfaces']()[iface].iteritems() %}
      {% if v is iterable %}
        {% for i in v %}
          {% if i.type | default("") == "inet" or k == "inet" %}
            {% if not (iface == "lo" and i.address == "127.0.0.1") %}
              {% do ip_real.append("%s/%s" | format(i.address, i.netmask)) %}
            {% endif %}
          {% endif %}
        {% endfor %}
      {% endif %}
    {% endfor %}
    {# for ipv6 #}
    {% for i in salt['network.interfaces']()[iface]['inet6'] | default([]) %}
      {% do ip_real6.append("%s/%s" | format(i.address, i.prefixlen)) %}
    {% endfor %}

    {% set ip_real = ip_real|sort %}
    {% set ip_real6 = ip_real6|sort %}

    {% if ip_real != ip_seted[iface] %}
ipcheck.{{ iface }}:
  cmd.run:
    - name: "echo '{{ iface }}: {{ ip_real }} diff as expected {{ ip_seted[iface] }}'"
    {% endif %}

    {% for x in ip_seted6[iface] %}
      {% if x not in ip_real6 %}
ipcheck6.{{ iface }}:
  cmd.run:
    - name: "echo '{{ iface }}: {{ ip_seted6[iface] }} not include in real {{ ip_real6 }}'"
      {% endif %}
    {% endfor %}
  {% endfor %}
{% endif %}
{% endif %}
