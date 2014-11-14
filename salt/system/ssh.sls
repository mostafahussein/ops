{% import_yaml "config/ssh.yaml" as ssh with context %}

{% set groups = {} %}
{% for g in salt['group.getent']() %}
  {% do groups.update({g['gid']: g }) %}
{% endfor %}

{% for f in ssh.get('ssh_dirs') %}

  {% set userinfo = salt['user.info'](f.user) %}
  {% set group = groups[userinfo['gid']]['name'] %}
  {% set homedir = '/'.join((userinfo['home'], '.ssh')) %}

{{ homedir }}:
  file.directory:
    - user: {{ f.user }}
    - group: {{ group }}
    - mode: 0700
    - clean: true
    - exclude_pat: "E@^(config|known_hosts)$"
    - require:
        - file: {{ homedir }}/authorized_keys
  {% for p in f.privkeys|default() %}
        - file: {{ homedir }}/{{ p }}
  {% endfor %}

  {% for p in f.privkeys|default() %}
{{ homedir }}/{{ p }}:
  file.managed:
    - user: {{ f.user }}
    - group: {{ group }}
    - mode: 0400
    - replace: False
  {% endfor %}

{{ homedir }}/authorized_keys:
  file.managed:
    - source: salt://common/etc/ssh/authorized_keys
    - mode: 0400
    - user: {{ f.user }}
    - group: {{ group }}
    - template: jinja
    - defaults:
        allows: {{ f.pubkeys }}
{% endfor %}
