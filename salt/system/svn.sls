{% import_yaml "config/svn.yaml" as svn with context %}

{% for d in svn.dirs|default(()) %}
  {% set svn_status = salt['svn.status'](d, None, None, None, None, '--config-dir', '/tmp/.subversion')|replace('       ', ' ') %}
svn.status({{ d }}):
  cmd.run:
    - name: 'echo "{{ svn_status.split('\n')|join('/') }}"'
    - unless: "{{ svn_status }}"
{% endfor %}
