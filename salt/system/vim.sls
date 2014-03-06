/etc/vim/vimrc.local:
  file.managed:
    - source: salt://common/etc/vim/vimrc.local
    - mode: 644
    - user: root
    - group: root
