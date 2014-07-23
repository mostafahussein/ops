{% import_yaml "common/config/packages.yaml" as pkgs with context %}

{% set pkglist = ["git", "htop", "lsof", "mlocate", "pdsh",
  "strace", "tcpdump", "traceroute"] %}

{% if grains['os'] == "Gentoo" %}

  {% import_yaml "config/portage.yaml" as portage with context %}

  {% for f in ("package.keywords", "package.mask", "package.use", "repos.conf") %}
/etc/portage/{{ f }}:
  file.directory:
    - mode: 0755
    - user: root
    - group: root
    - clean: True
    {% if portage.confs is defined %}
    - require:
      {% for c in portage.confs %}
      - file: /etc/portage/{{ c.name }}
      {% endfor %}
    {% endif %}
  {% endfor %}

  {% for f in portage.confs %}
/etc/portage/{{ f.name }}:
  file.managed:
    - source: salt://common/etc/portage/{{ f.name }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    {% if f.attrs is defined %}
    - defaults:
        attrs: {{ f.attrs }}
    {% endif %}
  {% endfor %}

  {% do pkglist.extend(("iptraf-ng",)) %}

{% elif grains['os'] == "Ubuntu" %}

  {% import_yaml "config/apt.yaml" as apt with context %}
/etc/apt/sources.list:
  file.managed:
    - source: salt://etc/apt/sources.list
    - user: root
    - group: root
    - mode: 0644
    - template: jinja

  {% if apt.sources is defined and
    apt.sources is iterable %}
    {% for f in apt.get("sources", ()) %}
/etc/apt/sources.list.d/{{ f.name }}:
      {% if f.source is not defined %}
  file.absent
      {% else %}
  file.managed:
    - source: {{ f.source }}
    - user: root
    - group: root
    - mode: 0644
    - template: jinja
      {% endif %}
    {% endfor %}
  {% endif %}

  {% do pkglist.extend(("iptraf", "realpath")) %}

{% elif grains['os'] == "CentOS" %}
  {% import_yaml "config/yum.yaml" as yum with context %}

  {% if yum.repos is defined and
    yum.repos is iterable %}
    {% for f in yum.get("repos", ()) %}
/etc/yum.repos.d/{{ f.name }}:
      {% if f.source is not defined %}
  file.absent
      {% else %}
  file.managed:
    - source: {{ f.source }}
    - user: root
    - group: root
    - mode: 0644
    - template: jinja
      {% endif %}
    {% endfor %}
  {% endif %}

  {% if yum.gpgs is defined and
    yum.gpgs is iterable %}
    {% for f in yum.get("gpgs", ()) %}
/etc/pki/rpm-gpg/{{ f.name }}:
      {% if f.source is not defined %}
  file.absent
      {% else %}
  file.managed:
    - source: {{ f.source }}
    - user: root
    - group: root
    - mode: 0644
      {% endif %}
    {% endfor %}
  {% endif %}

  {% do pkglist.extend(("iptraf-ng", "realpath")) %}
{% endif %}

{% for i in pkglist %}
package.{{ i }}:
  pkg.installed:
    - name: {{ pkgs.get(i, i) }}
    - refresh: False
{% endfor %}

