{% if grains['os'] == "CentOS" %}
/etc/vimrc:
  file.managed:
    - source: salt://common/etc/vimrc.centos
    - mode: 644
    - user: root
    - group: root

/etc/vimrc.local:
{% else %}
/etc/vim/vimrc.local:
{% endif %}
  file.managed:
    - source: salt://common/etc/vim/vimrc.local
    - mode: 644
    - user: root
    - group: root
