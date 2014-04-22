{% import_yaml "config/salt.yaml" as salt with context %}

/etc/salt/grains:
  file.managed:
    - source: salt://etc/salt/grains
    - mode: 644
    - user: root
    - group: root
    - template: jinja

{% if grains['os'] == "Gentoo" %}
{% set minion_confs = ("aliases", "config", "master", "output") %}
{% else %}
{% set minion_confs = ("config", "master", "output") %}
{% endif %}

service.salt-minion:
  service.running:
    - name: salt-minion
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/lib/python-exec/python2.7/salt-minion --log-level"
{% elif grains['os'] == "Ubuntu" %}
    - sig: "su -c salt-minion"
{% endif %}
    - watch:
{% for f in minion_confs %}
      - file: /etc/salt/minion.d/{{ f }}.conf
{% endfor %}

{% for s in minion_confs %}
/etc/salt/minion.d/{{ s }}.conf:
  file.managed:
    - source: salt://common/etc/salt/minion.d/{{ s }}.conf
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
{% endfor %}

service.salt-master:
{% if salt.get('is_master') %}

  {% set master_confs = ("config", "files", "pillar") %}

  service.running:
    - name: salt-master
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/lib/python-exec/python2.7/salt-master --log-level"
{% elif grains['os'] == "Ubuntu" %}
    - sig: "su -c salt-master"
{% endif %}
    - watch:
  {% for f in master_confs %}
      - file: /etc/salt/master.d/config.conf
      - file: /etc/salt/master.d/files.conf
      - file: /etc/salt/master.d/pillar.conf
  {% endfor %}

  {% for f in master_confs %}
/etc/salt/master.d/{{ f }}.conf:
  file.managed:
    - source: salt://common/etc/salt/master.d/{{ f }}.conf
    - mode: 644
    - user: root
    - group: root
  {% endfor %}
{% else %}
  service.dead:
    - enable: False
    - name: salt-master
{% endif %}
