# @todo check swap label

{% import_yaml "config/mount.yaml" as mount with context %}

{% if mount.devices is not defined %}

mount.devices:
  cmd.run:
    - name: "echo 'devices not defined in mount.yaml, please check!'"

{% else %}

  {% set mswaps =  salt['mount.swaps']() %}
  {% set mactives =  salt['mount.active']() %}

  {% for d in mount.devices %}
    {% set fs = d['fs'] %}
    {% set mp = d['mp'] %}
    {% set dev = d['device'] %}
    {% set label = d['label'] %}
    {% set opts = d.get('opts') %}
    {% set maxmount = d.get('maxmount', '-1') %}
    {% set interval = d.get('interval', '0') %}

    {% if fs in ('ext2', 'ext3', 'ext4') %}
      {% if salt['file.access'](dev, 'r') %}
        {% set attrs = salt['extfs.attributes'](dev, args="h") %}
        {% set rlabel = attrs.get("Filesystem volume name") %}
        {% set rmaxmount = attrs.get("Maximum mount count") %}
        {% set rinterval = attrs.get("Check interval") %}
        {% if rinterval %}
          {% set rinterval = rinterval.split()[0] %}
        {% endif %}

        {% if rlabel != label %}
label.{{ dev }}:
  cmd.run:
    - name: "echo 'label of [{{ dev }}] is [{{ rlabel }}], != [{{ label }}]'"
        {% endif %}

        {% if rmaxmount != maxmount %}
maxmount.{{ dev }}:
  cmd.run:
    - name: "echo 'maxmount of [{{ dev }}] is [{{ rmaxmount }}], != [{{ maxmount }}]'"
        {% endif %}

        {% if rinterval != interval %}
interval.{{ dev }}:
  cmd.run:
    - name: "echo 'check interval of [{{ dev }}] is [{{ rinterval }}], != [{{ interval }}]'"
        {% endif %}
      {% else %}
device.{{ dev }}:
  cmd.run:
    - name: "echo 'device {{ dev }} not exist or not readable.'"
      {% endif %}
    {% elif fs in ("vfat",) %}
      {% set rlabel = salt['cmd.run'](' '.join(('dosfslabel', dev))) %}
        {% if rlabel != label %}
label.{{ dev }}:
  cmd.run:
    - name: "echo 'label of [{{ dev }}] is [{{ rlabel }}], != [{{ label }}]'"
        {% endif %}

    {% elif fs in ("devpts", "sysfs", "swap", "tmpfs", "proc") %}
    {% elif fs in ("none",) %}
      {% if opts != "bind" %}
mount.none.{{ mp }}:
  cmd.run:
    - name: "echo '[{{ mp }}]'s fs is [{{ fs }}], but opts[{{ opts }}] != [bind].'"
      {% else %}
      {# @todo check device #}
      {% endif %}
    {% else %}
mount.fs.{{ mp }}:
  cmd.run:
    - name: "echo 'fs[{{ fs }}] of [{{ dev }}] not supported yet.'"
    {% endif %}
    {% if fs == "swap" %}
      {% set actived = False %}
      {% if dev not in mswaps.keys() %}
        {% set rdev = salt['file.stats'](dev).get('target') %}
        {% if rdev in mswaps.keys() %}
          {% set actived = True %}
        {% endif %}
      {% else %}
        {% set actived = True %}
      {% endif %}
      {% if not actived %}
swap.{{ mp }}:
  cmd.run:
    - name: "echo 'swap [{{ dev }}] isn't activated.'"
      {% endif %}
    {% else %}
      {% if fs in ('ext2', 'ext3', 'ext4') %}
{{ mp }}/lost+found:
  file.directory:
    - user: root
    - group: root
    - mode: 0700
      {% endif %}
      {% if mp not in mactives.keys() %}
mount.{{ mp }}:
  cmd.run:
    - name: "echo '{{ mp }} isn't mounted.'"
      {% else %}
        {% set attrs = mactives[mp] %}
        {% set alt_dev = attrs.get('alt_device') %}
        {% if alt_dev != dev %}
mount.dev.{{ dev }}:
  cmd.run:
    - name: "echo '{{ mp }} is mounted, but device is {{ alt_dev }}, != {{ dev }}'"
        {% endif %}
      {% endif %}
      {% if d.get('bind') %}
        {% set bmp = "/mnt/%s%s" | format(grains['os']|lower, mp) %}
        {% set bmp = bmp.rstrip('/') %}
        {% if bmp not in mactives.keys() %}
mount.bind.{{ bmp }}:
  cmd.run:
    - name: "echo '{{ bmp }} isn't mounted.'"
        {% else %}
          {% set attrs = mactives[bmp] %}
          {% set alt_dev = attrs.get('alt_device') %}
          {% if alt_dev != mp %}
mount.binddev.{{ mp }}:
  cmd.run:
    - name: "echo '{{ bmp }} is mounted, but device is {{ alt_dev }}, != {{ mp }}'"
          {% endif %}
          {% if dev != attrs.get('device') %}
mount.binddevice.{{ mp }}:
  cmd.run:
    - name: "echo '{{ bmp }} is mounted, but device is {{ attrs.get('device') }}, != {{ dev }}'"
          {% endif %}
        {% endif %}
      {% endif %}
    {% endif %}
  {% endfor %}
{% endif %}

{% if salt['file.access']("/proc/self/mountinfo", 'r') %}
  {% set duplicated_mps = salt['cmd.run']('awk \'{ minfo[$5]++; } END { for (m in minfo) { if (minfo[m] > 1) print m, minfo[m] }}\' /proc/self/mountinfo').splitlines() %}
{% elif salt['file.access']("/proc/self/mounts", 'r') %}
  {% set duplicated_mps = salt['cmd.run']('awk \'{if ($3 != "rootfs") { minfo[$2]++; } } END { for (m in minfo) { if (minfo[m] > 1) print m, minfo[m] }}\' /proc/self/mounts').splitlines() %}
{% else %}
  {% set duplicated_mps = () %}
{% endif %}

{% for dmp in duplicated_mps %}
  {% set mp, mc = dmp.split() %}
mount.duplicated.{{ mp }}:
  cmd.run:
    - name: 'echo "{{ mp }} is mounted by {{ mc }} times, please fix!"'
{% endfor %}

/etc/fstab:
  file.managed:
    - source: salt://common/etc/fstab
    - mode: 644
    - user: root
    - group: root
    - template: jinja

/mnt/{{ grains['os'] | lower }}:
  file.directory:
{% if grains['os'] == "CentOS" %}
    - mode: 0555
{% else %}
    - mode: 0755
{% endif %}
    - user: root
    - group: root
