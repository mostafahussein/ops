{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/cpufrequtils.yaml" as cpufrequtils with context %}

{% set svcname = "cpufrequtils" %}

{% if grains['os'] == "Gentoo" %}
  {% set svcname = "cpupower" %}
{% endif %}

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
  {% if grains['os'] == "Gentoo" %}
    - name: {{ pkgs.cpupower | default('cpupower') }}
  {% else %}
    - name: {{ pkgs.cpufrequtils | default('cpufrequtils') }}
  {% endif %}
    - refresh: False
  service.enabled:
    - name: {{ svcname }}
    - reload: True
    - watch:
      - file: service.cpufrequtils
  file.managed:
  {% if grains['os'] == "Gentoo" %}
    - name: /etc/conf.d/{{ svcname }}
    - source: salt://common/etc/conf.d/{{ svcname }}
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
    - name: {{ svcname }}
  file.absent:
    - name: /etc/default/cpufrequtils

  {% if grains['os'] == "Ubuntu" %}
service.loadcpufreq:
  service.disabled:
    - name: loadcpufreq
  {% endif %}

{% endif %}
