{% import_yaml "config/salt.yaml" as salt with context %}

/etc/salt/grains:
  file.managed:
    - source: salt://etc/salt/grains
    - mode: 644
    - user: root
    - group: root
    - template: jinja

service.salt-minion:
  service.running:
    - name: salt-minion
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/lib/python-exec/python2.7/salt-minion --log-level"
{% elif grains['os'] == "Gentoo" %}
    - sig: "su -c salt-minion"
{% endif %}
    - watch:
      - file: service.salt-minion
      - file: /etc/salt/minion.d/config.conf
{% if grains['os'] == "Gentoo" %}
      - file: /etc/salt/minion.d/aliases.conf
{% endif %}
  file.managed:
    - name: /etc/salt/minion.d/master.conf
    - source: salt://common/etc/salt/minion.d/master.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja

{% if grains['os'] == "Gentoo" %}
{% set minion_configs = ("aliases", "config", "output") %}
{% else %}
{% set minion_configs = ("config", "output") %}
{% endif %}

{% for s in minion_configs %}
/etc/salt/minion.d/{{ s }}.conf:
  file.managed:
    - source: salt://common/etc/salt/minion.d/{{ s }}.conf
    - mode: 0644
    - user: root
    - group: root
{% endfor %}

service.salt-master:
{% if salt.get('is_salt_master') %}
  service.running:
    - name: salt-master
    - enable: True
    - sig: "/usr/lib/python-exec/python2.7/salt-master --log-level"
    - watch:
      - file: service.salt-master
      - file: /etc/salt/master.d/pillar.conf
  file.managed:
    - name: /etc/salt/master.d/files.conf
    - source: salt://common/etc/salt/master.d/files.conf
    - mode: 644
    - user: root
    - group: root

/etc/salt/master.d/pillar.conf:
  file.managed:
    - name: /etc/salt/master.d/pillar.conf
    - source: salt://common/etc/salt/master.d/pillar.conf
    - mode: 644
    - user: root
    - group: root
{% else %}
  service.disabled:
    - name: salt-master
{% endif %}
