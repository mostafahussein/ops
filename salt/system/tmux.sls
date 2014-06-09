{% import_yaml "common/config/packages.yaml" as pkgs with context %}

/etc/tmux.conf:
  pkg.installed:
    - name: {{ pkgs.get("tmux", "tmux") }}
    - refresh: False
  file.managed:
    - source: salt://common/etc/tmux.conf
    - mode: 644
    - user: root
    - group: root
