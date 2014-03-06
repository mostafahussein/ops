service.local:
# service.enabled:
#   - name: local
  file.symlink:
    - name: /etc/runlevels/default/local
    - user: root
    - group: root
    - target: /etc/init.d/local

/etc/local.d/sysctl.start:
  file.managed:
    - source: salt://common/etc/local.d/sysctl.start
    - mode: 755
    - user: root
    - group: root
