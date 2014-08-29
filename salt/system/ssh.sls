{% import_yaml "config/ssh.yaml" as ssh with context %}

{% for f in ssh.get('ssh_dirs') %}

{{ f.name }}:
  file.directory:
    - user: {{ f.user }}
    - group: {{ f.group }}
    - mode: 0700
    - clean: true
    - exclude_pat: "E@(^config$)|(^known_hosts$)"
    - require:
        - file: {{ f.name }}/authorized_keys
  {% for p in f.privkeys|default() %}
        - file: {{ f.name }}/{{ p }}
  {% endfor %}

  {% for p in f.privkeys|default() %}
{{ f.name }}/{{ p }}:
  file.managed:
    - user: {{ f.user }}
    - group: {{ f.group }}
    - mode: 0400
  {% endfor %}

{{ f.name }}/authorized_keys:
  file.managed:
    - source: salt://common/etc/ssh/authorized_keys
    - mode: 0400
    - user: {{ f.user }}
    - group: {{ f.group }}
    - template: jinja
    - defaults:
        allows: {{ f.pubkeys }}
{% endfor %}
