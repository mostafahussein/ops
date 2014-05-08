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
      - file: {{ f.name }}
{% endfor %}

/etc/conf.d/named:
  file.managed:
    - source: salt://common/etc/conf.d/named
    - mode: 0644
    - user: root
    - group: root
    - template: jinja

{% for f in named.get('named_confs', ()) %}
  {% if f.op is not defined %}
    {% set fop = "managed" %}
  {% else %}
    {% set fop = f.op %}
  {% endif %}
{{ f.name }}:
  file.{{ fop }}:
    - user: {{ f.user | default('root') }}
    - group: {{ f.group | default('named') }}
  {% if fop == "managed" %}
    - mode: {{ f.mode | default('0640')}}
    - source: salt:/{{ f.source | default(f.name) }}
    - template: jinja
  {% elif fop == "directory" %}
    - mode: {{ f.mode | default('0751') }}
  {% elif fop == "symlink" %}
    - target: {{ f.target }}
  {% else %}
    - mode: {{ f.mode }}
  {% endif %}
  {% if fop == "mknod" %}
    - ntype: {{ f.ntype }}
    - major: {{ f.major }}
    - minor: {{ f.minor }}
  {% endif %}
{% endfor %}
