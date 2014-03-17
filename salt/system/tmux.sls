/etc/tmux.conf:
  file.managed:
    - source: salt://common/etc/tmux.conf
    - mode: 644
    - user: root
    - group: root
