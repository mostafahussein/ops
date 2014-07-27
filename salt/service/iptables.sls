{% set idname = grains['id'].split('.')[0] %}

{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/iptables.yaml" as iptables with context %}

{% set rules_ipset = "" %}

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

  {% if grains['os'] in ("Ubuntu", "Gentoo") %}
    {% set action_set = {'-A': 'append', '-I': 'insert', '-D': 'delete' } %}
    {% if iptables.table is defined and iptables.table is iterable %}
      {% for t in iptables.table %}
        {% if t.rules is defined %}
          {% for r in t.rules %}
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
        {% endif %}
      {% endfor %}
    {% endif %}
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
      - salt://common/etc/iptables/rules_ipset
  {% else %}
  file.absent
  {% endif %}
{% endif %}
