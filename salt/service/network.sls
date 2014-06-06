{# @todo add strictly ipv6 check, complete match #}

{% import_yaml "config/nics.yaml" as nics with context %}
{% import_yaml "config/ip.yaml" as ip with context %}

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

{% if ip.lo is defined %}
  {% set ip_seted = ""|list %}
  {% for i in ip.lo %}
    {% do ip_seted.append("%s/%s" | format(i.addr, i.mask)) %}
  {% endfor %}
  {% set ip_seted = ip_seted|sort %}

  {% set ip_real = ""|list %}
  {% for i in salt['network.interfaces']()['lo']['inet'] %}
    {% if i.address != "127.0.0.1" %}
      {% do ip_real.append("%s/%s" | format(i.address, i.netmask)) %}
    {% endif %}
  {% endfor %}
  {% set ip_real = ip_real|sort %}

  {% if ip_real != ip_seted %}
ipcheck.lo:
  cmd.run:
    - name: "echo \"lo: {{ ip_real }} diff as expected {{ ip_seted }}\""
  {% endif %}
{% endif %}

{% if ip.nics is defined %}
  {% for l in ip.nics %}
    {% set ip_seted = ""|list %}
    {% set ip_seted6 = ""|list %}
    {% for i in l.ip %}
      {% if i.family|default("inet") == "inet6" %}
        {% do ip_seted6.append(i.addr) %}
      {% else %}
        {% do ip_seted.append("%s/%s" | format(i.addr, i.mask)) %}
      {% endif %}
    {% endfor %}
    {% set ip_seted = ip_seted|sort %}
    {% set ip_seted6 = ip_seted6|sort %}

    {% set ip_real = ""|list %}
    {% set ip_real6 = ""|list %}
    {# for ipv4 #}
    {% for k,v in salt['network.interfaces']()[l.name].iteritems() %}
      {% if v is iterable %}
        {% for i in v %}
          {% if i.type|default("") == "inet" or k == "inet" %}
            {% do ip_real.append("%s/%s" | format(i.address, i.netmask)) %}
          {% endif %}
        {% endfor %}
      {% endif %}
    {% endfor %}
    {# for ipv6 #}
    {% for i in salt['network.interfaces']()[l.name]['inet6'] %}
      {% do ip_real6.append("%s/%s" | format(i.address, i.prefixlen)) %}
    {% endfor %}

    {% set ip_real = ip_real|sort %}
    {% set ip_real6 = ip_real6|sort %}

    {% if ip_real != ip_seted %}
ipcheck.{{ l.name }}:
  cmd.run:
    - name: "echo '{{ l.name }}: {{ ip_real }} diff as expected {{ ip_seted }}'"
    {% endif %}

    {% for x in ip_seted6 %}
      {% if x not in ip_real6 %}
ipcheck6.{{ l.name }}:
  cmd.run:
    - name: "echo '{{ l.name }}: {{ ip_seted6 }} not include in real {{ ip_real6 }}'"
      {% endif %}
    {% endfor %}
  {% endfor %}
{% endif %}
