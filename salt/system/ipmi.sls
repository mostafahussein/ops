{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/ipmi.yaml" as ipmi with context %}

{% set kipmid_busy_file = '/sys/module/ipmi_si/parameters/kipmid_max_busy_us' %}

{% if salt['file.access'](kipmid_busy_file, 'f') %}
  {% set busy_time = ipmi.kipmid_max_busy_us|default('100') %}
  {% set rbusy_time = salt['cmd.run'](' '.join(('cat', kipmid_busy_file))).strip() %}
  {% if rbusy_time != busy_time %}
{{ kipmid_busy_file }}:
  cmd.run:
    - name: "echo '{{ busy_time }}' > {{ kipmid_busy_file }}"
  {% endif %}
{% endif %}

/etc/modprobe.d/ipmi.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 0400
    - source: salt://common/etc/modprobe.d/ipmi.conf
