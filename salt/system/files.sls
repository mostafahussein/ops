{% import_yaml "config/files.yaml" as files with context %}

{% if files.files is defined and files.files is iterable %}
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
    - source: {{ f.source }}
    - template: jinja
    - mode: {{ f.mode | default('0644')}}
    {% elif f.type == "recurse" %}
  file.recurse:
    - source: {{ f.source }}
    - clean: {{ f.clean | default(False) }}
      {% if f.exclude is defined %}
    - exclude_pat: "{{ f.exclude }}"
      {% endif %}
    - include_empty: {{ f.include_empty | default(False) }}
    - dir_mode: {{ f.dir_mode | default('0755') }}
    - file_mode: {{ f.file_mode | default('0644') }}
    {% elif f.type == "removed" %}
  file.absent
    {% endif %}
    {% if f.type != "removed" %}
    - user: {{ f.user | default('root') }}
    - group: {{ f.group | default('root') }}
    {% endif %}
  {% endfor %}
{% endif %}
