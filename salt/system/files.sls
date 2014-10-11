{% import_yaml "config/files.yaml" as files with context %}

{% if files.locations is defined and files.locations is iterable %}
  {% for l in files.locations %}
{{ l.location }}:
  file.directory:
    - user: {{ l.user | default('root') }}
    - group: {{ l.group | default('root') }}
    - mode: {{ l.mode | default('0755') }}
    - clean: {{ l.clean | default(True) }}
    {% if l.exclude is defined %}
    - exclude_pat: "{{ l.exclude }}"
    {% endif %}
    {% if l.files is defined %}
    - require:
      {% for f in l.files %}
      - file: {{ f.name }}
      {% endfor %}
    {% endif %}
    {% for f in l.files|default(()) %}
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
        {% if f.source is defined %}
    - source: {{ f.source }}
    - template: jinja
          {% if f.defaults is defined %}
    - defaults:
            {% for k,v in f.defaults.iteritems() %}
        "{{ k }}": "{{ v }}"
            {% endfor %}
          {% endif %}
        {% endif %}
    - mode: {{ f.mode | default('0644')}}
      {% elif f.type == "recurse" %}
  file.recurse:
    - source: {{ f.source }}
    - clean: {{ f.clean | default(True) }}
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
  {% endfor %}
{% endif %}
