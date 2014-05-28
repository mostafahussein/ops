{% set idname = grains['id'].split('.')[0] %}

{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/iptables.yaml" as iptables with context %}

{% if grains['os'] == "Ubuntu" %}
/etc/init.d/iptables:
  file.managed:
    - mode: 0755
    - user: root
    - group: root
    - source: salt://common/etc/init.d/iptables
{% endif %}

service.iptables:
  pkg.installed:
    - name: {{ pkgs.iptables | default('iptables') }}
    - refresh: False
  service:
    - name: iptables
{% if iptables.enabled is not defined %}
    - disabled
  file.absent:
  {% if grains['os'] == "Gentoo" %}
    - name: /var/lib/iptables/rules-save
  {% elif grains['os'] == "Ubuntu" %}
    - name: /etc/iptables/rules-save
  {% endif %}
{% else %}
    - enabled
    - reload: True
    - watch:
      - file: service.iptables
  file.managed:
  {% if grains['os'] == "Gentoo" %}
    - name: /var/lib/iptables/rules-save
    - source:
      - salt://var/lib/iptables/rules-save.{{ idname }}
    {% if iptables.rules is defined %}
      - salt://var/lib/iptables/{{ iptables.rules }}
    {% endif %}
  {% elif grains['os'] == "Ubuntu" %}
    - name: /etc/iptables/rules_iptables
    - source:
      - salt://etc/iptables/rules-save.{{ idname }}
    {% if iptables.rules is defined %}
      - salt://etc/iptables/{{ iptables.rules }}
    {% endif %}
  {% endif %}
    - mode: 0600
    - user: root
    - group: root
    - template: jinja

  {% if grains['os'] == "Gentoo" %}
/etc/conf.d/iptables:
  file.managed:
    - source: salt://common/etc/conf.d/iptables
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
  {% endif %}
{% endif %}

service.ipset:
  pkg.installed:
    - name: {{ pkgs.ipset | default('ipset') }}
    - refresh: False
{% if grains['os'] == "Gentoo" %}
  {% if iptables.ipset_enabled is defined %}
  service.enabled:
    - name: ipset
    - watch:
      - file: service.ipset
  file.managed:
    - name: /var/lib/ipset/rules-save
    - mode: 0600
    - user: root
    - group: root
    - source:
      - salt://var/lib/ipset/rules-save.{{ idname }}
    {% if iptables.rules is defined %}
      - salt://var/lib/ipset/{{ iptables.ipset_rules }}
    {% endif %}

/etc/conf.d/ipset:
  file.managed:
    - source: salt://common/etc/conf.d/ipset
    - mode: 0644
    - user: root
    - group: root
  {% else %}
  service.disabled:
    - name: ipset
  file.absent:
    - name: /var/lib/ipset/rules-save
  {% endif %}
{% elif grains['os'] == "Ubuntu" %}
/etc/iptables/rules_ipset:
  {% if iptables.ipset_enabled is defined %}
  file.managed:
    - mode: 0600
    - user: root
    - group: root
    - source:
    {% if iptables.rules is defined %}
      - salt://etc/iptables/{{ iptables.ipset_rules }}
    {% endif %}
      - salt://etc/iptables/rules_ipset.{{ idname }}
  {% else %}
  file.absent
  {% endif %}
{% endif %}
