{% set idname = grains['id'].split('.')[0] %}

{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/iptables.yaml" as iptables with context %}

{% if grains['os'] == "Gentoo" %}
  {% set rules_ipset = "/var/lib/ipset/rules-save" %}
  {% set rules_iptables = "/var/lib/iptables/rules-save" %}
{% elif grains['os'] == "Ubuntu" %}
  {% set rules_ipset = "/etc/iptables/rules_ipset" %}
  {% set rules_iptables = "/etc/iptables/rules_iptables" %}

/etc/init.d/iptables:
  file.managed:
    - mode: 0755
    - user: root
    - group: root
    - source: salt://common/etc/init.d/iptables

/etc/iptables:
  file.directory:
    - mode: 755
    - user: root
    - group: root
    - makedirs: True

{% elif grains['os'] == "CentOS" %}
  {% set rules_iptables = "/etc/sysconfig/iptables" %}
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
    - name: {{ rules_iptables }}
{% else %}
    - enabled
    - reload: True
    - watch:
      - file: service.iptables
  {% if iptables.ipset_enabled is defined %}
      - file: {{ rules_ipset }}
    {% if grains['os'] == "Gentoo" %}
    - require:
      - service: service.ipset
    {% endif %}
  {% endif %}
  {% if grains['os'] == "Gentoo" %}
      - file: /etc/conf.d/iptables
  {% elif grains['os'] == "CentOS" %}
      - file: /etc/sysconfig/iptables-config
  {% endif %}
  file.managed:
    - name: {{ rules_iptables }}
    - source:
    {% if iptables.rules is defined %}
      - salt://etc/iptables/{{ iptables.rules }}
    {% endif %}
      - salt://etc/iptables/rules-save.{{ idname }}
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
    - template: jinja
    - source:
    {% if iptables.ipset_rules is defined %}
      - salt://var/lib/ipset/{{ iptables.ipset_rules }}
    {% endif %}
      - salt://var/lib/ipset/rules-save.{{ idname }}

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
    - template: jinja
    - source:
    {% if iptables.ipset_rules is defined %}
      - salt://etc/iptables/{{ iptables.ipset_rules }}
    {% endif %}
      - salt://etc/iptables/rules_ipset.{{ idname }}
  {% else %}
  file.absent
  {% endif %}
{% endif %}
