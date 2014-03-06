{% import_yaml "config/iptables.yaml" as iptables with context %}

service.iptables:
  service:
    - name: iptables
{% if not iptables.get('iptables_enabled') %}
    - disabled
{% else %}
    - enabled
    - reload: True
    - watch:
      - file: service.iptables
  file.managed:
    - name: /var/lib/iptables/rules-save
    - mode: 0600
    - user: root
    - group: root
    - template: jinja
    - source: salt://var/lib/iptables/{{ iptables['iptables_rules'] }}
{% endif %}

{% if iptables.get('iptables_enabled') %}
/etc/conf.d/iptables:
  file.managed:
    - source: salt://common/etc/conf.d/iptables
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
{% endif %}

{% if iptables.get('ipset_enabled') %}
service.ipset:
  service.enabled:
    - name: ipset
    - watch:
      - file: service.ipset
  file.managed:
    - name: /var/lib/ipset/rules-save
    - mode: 0600
    - user: root
    - group: root
    - source: salt://var/lib/ipset/{{ iptables['ipset_rules'] }}

/etc/conf.d/ipset:
  file.managed:
    - source: salt://common/etc/conf.d/ipset
    - mode: 0644
    - user: root
    - group: root
{% else %}
service.ipset:
  service.disabled:
    - name: ipset
{% endif %}
