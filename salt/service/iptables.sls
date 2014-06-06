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
  {% elif grains['os'] == "CentOS" %}
    - name: /etc/sysconfig/iptables
  {% endif %}
{% else %}
    - enabled
    - reload: True
    - watch:
      - file: service.iptables
  {% if grains['os'] == "Gentoo" %}
      - file: /etc/conf.d/iptables
  {% elif grains['os'] == "CentOS" %}
      - file: /etc/sysconfig/iptables-config
  {% endif %}
  file.managed:
  {% if grains['os'] == "Gentoo" %}
    - name: /var/lib/iptables/rules-save
  {% elif grains['os'] == "Ubuntu" %}
    - name: /etc/iptables/rules_iptables
  {% elif grains['os'] == "CentOS" %}
    - name: /etc/sysconfig/iptables
  {% endif %}
    - source:
      - salt://etc/iptables/rules-save.{{ idname }}
    {% if iptables.rules is defined %}
      - salt://etc/iptables/{{ iptables.rules }}
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
  {% elif grains['os'] == "CentOS" %}
/etc/sysconfig/iptables-config:
  file.managed:
    - source: salt://common/etc/sysconfig/iptables-config
    - mode: 0600
    - user: root
    - group: root
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
