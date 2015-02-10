{% import_yaml "config/git.yaml" as git with context %}

{% if git.dirs is iterable %}
  {% for d in git.dirs %}
    {% set git_cmd = 'git -C %s status -s'|format(d) %}
    {% set git_status = salt['cmd.run_all'](git_cmd, env={'LC_ALL': 'en_US.UTF-8'}) %}
    {% if git_status.get('retcode') != 0 %}
      {% set git_result = "`%s' failed w/ %d"|format(git_cmd, git_status.get('retcode')) %}
    {% else %}
      {% if git_status.get('stderr') %}
        {% set git_result = "`%s' return error '%s'"|format(git_cmd, git_status.get('stderr')) %}
      {% elif git_status.get('stdout') %}
        {% set git_result = git_status.get('stdout') %}
      {% else %}
        {% set git_result = "" %}
      {% endif %}
    {% endif %}
    {% if git_result %}
git.status.{{ d }}:
  cmd.run:
    - name: "echo {{ git_result.split('\n')|join(',') }}"
    {% endif %}
  {% endfor %}
{% endif %}

{% if git.files is defined and git.files is iterable %}
  {% for f in git.get("files", ()) %}
{{ f.name }}:
    {% if f.source is not defined %}
  file.absent
    {% else %}
  file.managed:
    - source: {{ f.source }}
    - user: root
    - group: root
    - mode: {{ f.mode|default('0644') }}
    - template: jinja
    {% endif %}
  {% endfor %}
{% endif %}
