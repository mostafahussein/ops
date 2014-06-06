{% if grains['os'] == "Ubuntu" %}

alternative.vi:
  pkg.installed:
    - name: vim
    - refresh: False
  alternatives.set:
    - name: vi
    - path: /usr/bin/vim.basic

alternative.awk:
  pkg.installed:
    - name: gawk
    - refresh: False
  alternatives.set:
    - name: awk
    - path: /usr/bin/gawk

{% endif %}
