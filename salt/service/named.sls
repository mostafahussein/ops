{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/named.yaml" as named with context %}
service.named:
  pkg.installed:
    - name: {{ pkgs.named }}
    - refresh: False
  service.running:
    - name: named
    - enable: True
    - sig: "/usr/sbin/named -u named -t /chroot/dns"
    - watch:
{% for f in named.get('named_confs', ()) %}
      - file: {{ f }}
{% endfor %}
{% for f in named.get('named_symlinks', ()) %}
      - file: {{ f.name }}
{% endfor %}

{% for f in named.get('named_confs', ()) %}
{{ f }}:
  file.managed:
    - source: salt:/{{ f }}
    - mode: 0640
    - user: root
    - group: named
    - template: jinja
{% endfor %}

{% for f in named.get('named_symlinks', ()) %}
{{ f.name }}:
  file.symlink:
    - user: root
    - group: named
    - target: {{ f.target }}
{% endfor %}

/etc/conf.d/named:
  file.managed:
    - source: salt://common/etc/conf.d/named
    - mode: 0644
    - user: root
    - group: root
    - template: jinja

{% for f in named.get('named_chroots', ()) %}
{{ f.name }}:
  file.{{ f.op }}:
    - user: {{ f.user }}
    - group: {{ f.group }}
  {% if f.op == "symlink" %}
    - target: {{ f.target }}
  {% else %}
    - mode: {{ f.mode }}
  {% endif %}
  {% if f.op == "mknod" %}
    - ntype: {{ f.ntype }}
    - major: {{ f.major }}
    - minor: {{ f.minor }}
  {% endif %}
{% endfor %}
