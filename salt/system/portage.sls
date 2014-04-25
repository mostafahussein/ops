{% if grains['os'] == "Gentoo" %}

  {% for f in ("make.conf", "local.conf",
    "package.use/common",
    "package.keywords/redis",
    "package.keywords/salt",
    "package.keywords/web-server") %}
/etc/portage/{{ f }}:
  file.managed:
    - source: salt://common/etc/portage/{{ f }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
  {% endfor %}

{% endif %}
