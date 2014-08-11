{% import_yaml "common/config/packages.yaml" as pkgs with context %}
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
pkg.salt:
  pkg.installed:
    - name: {{ pkgs.salt }}
    - refresh: False
{% else %}
{% set minion_confs = ("config", "master", "output") %}
pkg.salt-minion:
  pkg.installed:
    - name: salt-minion
    - refresh: False
  {% if salt.get('is_master') %}
pkg.salt-master:
  pkg.installed:
    - name: salt-master
    - refresh: False
  {% endif %}
{% endif %}

service.salt-minion:
  service.running:
    - name: salt-minion
    - enable: True
{% if grains['os'] == "Gentoo" %}
    - sig: "/usr/lib/python-exec/python2.7/salt-minion --log-level"
{% else %}
    - sig: "/usr/bin/python /usr/bin/salt-minion"
{% endif %}
    - watch:
{% for f in minion_confs %}
      - file: /etc/salt/minion.d/{{ f }}.conf
{% endfor %}

/etc/salt/minion.d:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - clean: True
{% if minion_d_exclude is defined %}
    - exclude_pat: {{ minion_d_exclude }}
{% endif %}
    - require:
{% for s in minion_confs %}
        - file: /etc/salt/minion.d/{{ s }}.conf
{% endfor %}

{% for s in minion_confs %}
/etc/salt/minion.d/{{ s }}.conf:
  file.managed:
    - source:
       - salt://etc/salt/minion.d/{{ s }}.conf
       - salt://common/etc/salt/minion.d/{{ s }}.conf
    - mode: 0644
    - user: root
    - group: root
    - template: jinja
{% endfor %}

service.salt-master:
{% if salt.get('is_master') %}

  {% set master_confs = ("config", "files", "output", "pillar", "threads") %}

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
      - file: /etc/salt/master.d/{{ f }}.conf
  {% endfor %}

/etc/salt/master.d:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - clean: True
{% if master_d_exclude is defined %}
    - exclude_pat: {{ master_d_exclude }}
{% endif %}
    - require:
{% for s in master_confs %}
        - file: /etc/salt/master.d/{{ s }}.conf
{% endfor %}

  {% for f in master_confs %}
/etc/salt/master.d/{{ f }}.conf:
  file.managed:
    - source:
       - salt://etc/salt/master.d/{{ f }}.conf
       - salt://common/etc/salt/master.d/{{ f }}.conf
    - mode: 644
    - user: root
    - group: root
  {% endfor %}
{% else %}
  service.dead:
    - enable: False
    - name: salt-master
{% endif %}
