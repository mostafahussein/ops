{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/named.yaml" as named with context %}
service.named:
  pkg.installed:
    - name: {{ pkgs.named }}
    - refresh: False
  service.running:
{% if grains['os'] == "Ubuntu" %}
    - name: bind9
    - sig: "/usr/sbin/named -u bind -t /var/lib/named"
{% else %}
    - name: named
  {% if grains['os'] == "Gentoo" %}
    - sig: "/usr/sbin/named -u named -t /chroot/dns"
  {% elif grains['os'] == "CentOS" %}
    - sig: "/usr/sbin/named -u named -t /var/named/chroot"
  {% endif %}
{% endif %}
    - enable: {{ named.enable_sysvinit | default(True) }}
    - watch:
      - file: sysconfig.named
{% for f in named.get('named_confs', ()) %}
      - file: {{ f.name }}
{% endfor %}

sysconfig.named:
{% if grains['os'] == "Gentoo" %}
  file.managed:
    - name: /etc/conf.d/named
    - source: salt://common/etc/conf.d/named
{% elif grains['os'] == "CentOS" %}
  file.managed:
    - name: /etc/sysconfig/named
    - source: salt://common/etc/sysconfig/named
{% elif grains['os'] == "Ubuntu" %}
  file.managed:
    - name: /etc/default/bind9
    - source: salt://common/etc/default/bind9
{% endif %}
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
  {% if grains['os'] == "Ubuntu" %}
    - group: {{ f.group | default('bind') }}
  {% else %}
    - group: {{ f.group | default('named') }}
  {% endif %}
  {% if fop == "managed" %}
    - mode: {{ f.mode | default('0640')}}
    - source: salt:/{{ f.source | default(f.name) }}
    - template: jinja
  {% elif fop == "directory" %}
    - mode: {{ f.mode | default('0751') }}
    {% if f.makedirs is defined %}
    - makedirs: {{ f.makedirs }}
    {% endif %}
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
