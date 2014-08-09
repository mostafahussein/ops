{# @todo add strictly ipv6 check, complete match #}

{% import_yaml "config/nics.yaml" as nics with context %}
{% import_yaml "config/ip.yaml" as ip with context %}
{% set idname = grains['id'].split(".")[0] %}

{% set nicconfs = ip.nics.get(grains['id'], ()) %}
{% if not nicconfs %}
  {% set nicconfs = ip.nics.get(idname, ()) %}
{% endif %}

{% if grains['os'] == "Gentoo" %}

  {% set netmask2len = {
    '128.0.0.0': '1',        '192.0.0.0': '2',        '224.0.0.0': '3',
    '240.0.0.0': '4',        '248.0.0.0': '5',        '252.0.0.0': '6',
    '254.0.0.0': '7',        '255.0.0.0': '8',        '255.128.0.0': '9',
    '255.192.0.0': '10',     '255.224.0.0': '11',     '255.240.0.0': '12',
    '255.248.0.0': '13',     '255.252.0.0': '14',     '255.254.0.0': '15',
    '255.255.0.0': '16',     '255.255.128.0': '17',   '255.255.192.0': '18',
    '255.255.224.0': '19',   '255.255.240.0': '20',   '255.255.248.0': '21',
    '255.255.252.0': '22',   '255.255.254.0': '23',   '255.255.255.0': '24',
    '255.255.255.128': '25', '255.255.255.192': '26', '255.255.255.224': '27',
    '255.255.255.240': '28', '255.255.255.248': '29', '255.255.255.252': '30',
    '255.255.255.252': '31', '255.255.255.255': '32',
  } %}

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

{% elif grains["os"] == "CentOS" %}

  {% set lo_is_defined = False %}

  {% for l in nicconfs %}
    {% if l.name == "lo" %}{% set lo_is_defined = True %}{% endif %}
    {% if l.type.split('_')[0] == 'host' %}
/etc/sysconfig/network-scripts/ifcfg-{{ l.name }}:
  file.managed:
    - source:
  {% if nics is defined and nics.netconf is defined %}
      - {{ nics.netconf }}
  {% endif %}
      - salt://etc/sysconfig/network-scripts/ifcfg.{{ grains['id'] }}
      - salt://etc/sysconfig/network-scripts/ifcfg.{{ grains['id'].split(".")[0] }}
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        name: {{ l.name }}
        ip: {{ l.ip }}
    {% endif %}
  {% endfor %}

  {% if lo_is_defined is not defined %}
/etc/sysconfig/network-scripts/ifcfg-lo:
  file.managed:
    - source:
      - salt://common/etc/sysconfig/network-scripts/ifcfg.centos
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        name: "lo"
  {% endif %}

{% endif %}

{% if ip.nics is defined %}

  {% set vip = {} %}
  {% for i in nicconfs %}
    {% if i.vip is defined %}
      {% if i.name not in vip %}
        {% do vip.update({i.name:[]}) %}
      {% endif %}
      {% for j in i.vip %}
        {% do vip[i.name].append(j) %}
      {% endfor %}
    {% endif %}
  {% endfor %}

  {% set ip_seted = {} %}
  {% set ip_seted6 = {} %}
  {% for l in nicconfs %}{%- if l.type.split('_')[0] == 'host' -%}
    {% set iface = l.name.split(":")[0] %}
    {% if iface not in ip_seted %}
      {% do ip_seted.update({iface:[]}) %}
    {% endif %}
    {% if iface not in ip_seted6 %}
      {% do ip_seted6.update({iface:[]}) %}
    {% endif %}
    {% for i in l.get('ip', ()) %}
      {% if ':' in i.addr %}
        {% do ip_seted6[iface].append(i.addr) %}
      {% else %}
        {% do ip_seted[iface].append(i.addr) %}
      {% endif %}
    {% endfor %}
  {% endif %}{% endfor %}
  {# For lo interface #}
  {% if 'lo' not in ip_seted %}
    {% do ip_seted.update({'lo':[]}) %}
    {% do ip_seted6.update({'lo':[]}) %}
  {% endif %}
  {% if grains['os'] == "Gentoo" %}
    {% do ip_seted['lo'].append('127.0.0.1/8') %}
  {% else %}
  {% do ip_seted['lo'].append('127.0.0.1/255.0.0.0') %}
  {% endif %}
  {% do ip_seted6['lo'].append('::1/128') %}
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
            {% if grains['os'] == "Gentoo" %}
              {% set addr_mask = "%s/%s" | format(i.address, netmask2len[i.netmask]) %}
            {% else %}
              {% set addr_mask = "%s/%s" | format(i.address, i.netmask) %}
            {% endif %}
            {% if addr_mask not in vip.get(iface, []) %}
              {% do ip_real.append(addr_mask) %}
            {% endif %}
          {% endif %}
        {% endfor %}
      {% endif %}
    {% endfor %}

    {# for ipv6 #}
    {% for i in salt['network.interfaces']()[iface]['inet6'] | default([]) %}
      {# @todo exclude by exact match, i.e. test fe80::/10 #}
      {% if not (i.address.startswith('fe80::') and i.prefixlen == 64) %}
        {% do ip_real6.append("%s/%s" | format(i.address, i.prefixlen)) %}
      {% endif %}
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
