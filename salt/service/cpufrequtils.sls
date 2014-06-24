{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/cpufrequtils.yaml" as cpufrequtils with context %}

{% set cpufreq_dir = "/sys/devices/system/cpu" %}
{% set cpufreq_file = "cpufreq/scaling_governor" %}

{% if salt['file.access']('/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor', 'f') %}

  {% for i in range(grains['num_cpus']) %}
governor.cpu{{ i }}:
  cmd.run:
    - name: 'echo {{ cpufrequtils.governor }} > {{ cpufreq_dir }}/cpu{{ i }}/{{ cpufreq_file }}'
    - unless: "grep '{{ cpufrequtils.governor }}' {{ cpufreq_dir }}/cpu{{ i }}/{{ cpufreq_file }}"
  {% endfor %}

service.cpufrequtils:
  pkg.installed:
    - name: {{ pkgs.cpufrequtils | default('cpufrequtils') }}
    - refresh: False
  service.enabled:
    - name: cpufrequtils
    - reload: True
    - watch:
      - file: service.cpufrequtils
  file.managed:
  {% if grains['os'] == "Gentoo" %}
    - name: /etc/conf.d/cpufrequtils
    - source: salt://common/etc/conf.d/cpufrequtils
  {% elif grains['os'] == "Ubuntu" %}
    - name: /etc/default/cpufrequtils
    - source: salt://common/etc/default/cpufrequtils
  {% endif %}
    - user: root
    - group: root
    - mode: 0644
    - template: jinja

  {% if grains['os'] == "Ubuntu" %}
service.loadcpufreq:
  service.enabled:
    - name: loadcpufreq
    - reload: True
  {% endif %}

{% else %}

service.cpufrequtils:
  service.disabled:
    - name: cpufrequtils
  file.absent:
    - name: /etc/default/cpufrequtils

  {% if grains['os'] == "Ubuntu" %}
service.loadcpufreq:
  service.disabled:
    - name: loadcpufreq
  {% endif %}

{% endif %}
