{% import_yaml "config/udev.yaml" as udev with context %}

{% if grains['os'] == "Gentoo" %}

service.netmount:
  service.disabled:
    - name: netmount

eselect.profile:
  eselect.set:
    - name: profile
    - target: hardened/linux/amd64

  {% for f in ("conf.d/hwclock", "env.d/99local", "inittab", "locale.gen",
    "timezone") %}
/etc/{{ f }}:
  file.managed:
    - source: salt://common/etc/{{ f }}
    - mode: 644
    - user: root
    - group: root
    - template: jinja
  {% endfor %}

telinit q:
  cmd.wait:
    - cwd: /
    - watch:
      - file: /etc/inittab

/etc/securetty:
  file.managed:
    - source: salt://common/etc/securetty.gentoo
    - mode: 600
    - user: root
    - group: root

/etc/updatedb.conf:
  file.managed:
    - source: salt://common/etc/updatedb.conf.gentoo
    - mode: 644
    - user: root
    - group: root
    - template: jinja

/etc/udev/rules.d/70-persistent-net.rules:
  file.absent

  {% for f in ("80-net-name-slot.rules", "80-net-setup-link.rules") %}
/etc/udev/rules.d/{{ f }}:
    {% if udev.predictable_nic_name is defined %}
  file.absent
    {% else %}
  file.symlink:
    - user: root
    - group: root
    - target: /dev/null
    {% endif %}
  {% endfor %}

{% endif %}

/etc/runlevels:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - clean: True
    - exclude_pat: "E@(boot|default|nonetwork|shutdown|single|sysinit)"

{% set runlevels = {
  'boot': (
    'bootmisc', 'consolefont', 'fsck', 'hostname', 'hwclock', 'keymaps',
    'localmount', 'loopback', 'modules', 'mtab', 'net.lo', 'procfs', 'root',
    'swap', 'swapfiles', 'sysctl', 'termencoding', 'tmpfiles.setup',
    'urandom'),
  'nonetwork': ('local',),
  'shutdown': ('killprocs', 'mount-ro', 'savecache'),
  'single': (),
  'sysinit': ('devfs', 'dmesg', 'sysfs', 'tmpfiles.dev', 'udev', 'udev-mount'),
} %}

{% for r,v in runlevels.iteritems() %}
  {% for s in v %}
/etc/runlevels/{{ r }}/{{ s }}:
  file.symlink:
    - user: root
    - group: root
    - target: /etc/init.d/{{ s }}
  {% endfor %}

  {% if v %}
/etc/runlevels/{{ r }}:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - clean: True
    - require:
    {% for s in v %}
        - file: /etc/runlevels/{{ r }}/{{ s }}
    {% endfor %}
  {% endif %}
{% endfor %}
