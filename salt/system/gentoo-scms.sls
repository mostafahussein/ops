{% if grains['os'] == "Gentoo" %}

/etc/portage/package.keywords/redmine:
  file.managed:
    - source: salt://common/etc/portage/package.keywords/redmine
    - mode: 644
    - user: root
    - group: root

/etc/portage/package.mask/redmine:
  file.managed:
    - source: salt://common/etc/portage/package.mask/redmine
    - mode: 644
    - user: root
    - group: root

{% endif %}
