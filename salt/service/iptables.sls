{% set idname = grains['id'].split('.')[0] %}

{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/iptables.yaml" as iptables with context %}

{% set do_ipset = iptables.ipset_enabled|default(False) %}
{% set do_iptables = iptables.enabled|default(False) %}

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
    - source: salt://common/etc/init.d/iptables.{{ grains['os'] | lower }}

/etc/iptables:
  file.directory:
    - mode: 755
    - user: root
    - group: root
    - makedirs: True

{% elif grains['os'] == "CentOS" %}
  {% set rules_ipset = "/etc/sysconfig/ipset" %}
  {% set rules_iptables = "/etc/sysconfig/iptables" %}

/etc/rc.d/init.d/iptables:
  file.managed:
    - mode: 0755
    - user: root
    - group: root
    - source: salt://common/etc/init.d/iptables.{{ grains['os'] | lower }}

{% endif %}

service.iptables:
  pkg.installed:
    - name: {{ pkgs.iptables | default('iptables') }}
    - refresh: False
  service:
    - name: iptables
{% if not do_iptables %}
    - disabled
  file.absent:
    - name: {{ rules_iptables }}
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
  {% if do_ipset %}
      - file: {{ rules_ipset }}
    {% if grains['os'] == "Gentoo" %}
    - require:
      - service: service.ipset
    {% endif %}
  {% endif %}
  file.managed:
    - name: {{ rules_iptables }}
    - source:
    {% if iptables.rules is defined %}
      - salt://etc/iptables/{{ iptables.rules }}
    {% endif %}
      - salt://common/etc/iptables/rules_iptables
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

  {% set version = [] %}
  {% for v in salt['iptables.version']().lstrip('v').split(".") %}
    {% do version.append(v|int) %}
  {% endfor %}

  {# "-C" option appears since version 1.4.11 #}
  {% if version >= [1, 4, 11] %}
    {% set action_set = {'-A': 'append', '-I': 'insert', '-D': 'delete' } %}
    {% for t in iptables.table|default(()) %}
      {% for r in t.rules|default(()) %}
        {% if r.do_check|default(True)  %}
{{ r.name }}:
  iptables.{{ action_set[r.action|default(t.action)] }}:
    - table: {{ t.name }}
          {% for k,v in r.iteritems() %}
            {% if k not in ("do_check", "name", "action", "use") %}
    - {{ k }}: {{ v }}
            {% endif %}
          {% endfor %}
        {% endif %}
      {% endfor %}
    {% endfor %}
  {% endif %}

{% endif %}

service.ipset:
  pkg.installed:
    - name: {{ pkgs.ipset | default('ipset') }}
    - refresh: False
{% if grains['os'] == "Gentoo" %}
  {% if do_ipset %}
  service.enabled:
    - name: ipset
    - watch:
      - file: {{ rules_ipset }}

/etc/conf.d/ipset:
  file.managed:
    - source: salt://common/etc/conf.d/ipset
    - mode: 0644
    - user: root
    - group: root
  {% else %}
  service.disabled:
    - name: ipset
  {% endif %}
{% endif %}

{% if rules_ipset %}
{{ rules_ipset }}:
  {% if do_ipset %}
  file.managed:
    - mode: 0600
    - user: root
    - group: root
    - template: jinja
    - source:
    {% if iptables.ipset_rules is defined %}
      - salt://etc/iptables/{{ iptables.ipset_rules }}
    {% endif %}
      - salt://common/etc/iptables/rules_ipset
  {% else %}
  file.absent
  {% endif %}
{% endif %}
