{% import_yaml "config/files.yaml" as files with context %}

{% for f in files.files %}
{{ f.name }}:
  {% if f.type == "dir" %}
  file.directory:
    - makedirs: True
    - mode: {{ f.mode | default('0755')}}
  {% elif f.type == "symlink" %}
  file.symlink:
    - target: {{ f.target }}
  {% elif f.type == "file" %}
  file.managed:
    - source: {{ f.src }}
    - template: jinja
    - mode: {{ f.mode | default('0644')}}
  {% endif %}
    - user: {{ f.user | default('root') }}
    - group: {{ f.group | default('root') }}
{% endfor %}
