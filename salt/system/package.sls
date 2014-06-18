{% import_yaml "common/config/packages.yaml" as pkgs with context %}

{% set pkglist = ["git", "htop", "lsof", "mlocate", "strace", "tcpdump"] %}

{% if grains['os'] == "Gentoo" %}

  {% import_yaml "config/portage.yaml" as portage with context %}

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

  {% for f in portage.repos_confs %}
/etc/portage/repos.conf/{{ f.name }}:
  file.managed:
    - source: salt://common/etc/portage/repos.conf/{{ f.name }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    {% if f.attrs is defined %}
    - defaults:
        attrs: {{ f.attrs }}
    {% endif %}
  {% endfor %}

{% elif grains['os'] == "Ubuntu" %}

  {% do pkglist.append("realpath") %}

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
  file.managed:
    - source: {{ f.source }}
    - user: root
    - group: root
    - mode: 0644
    - template: jinja
    {% endfor %}
  {% endif %}

{% elif grains['os'] == "CentOS" %}
  {% do pkglist.append("realpath") %}
{% endif %}

{% for i in pkglist %}
package.{{ i }}:
  pkg.installed:
    - name: {{ pkgs.get(i, i) }}
    - refresh: False
{% endfor %}

