{% import_yaml "config/ssh.yaml" as ssh with context %}
{% for f in ssh.get('ssh_pubkeys') %}
{{ f.name }}:
  file.managed:
    - source: salt://common/etc/ssh/authorized_keys
    - mode: 0400
    - user: {{ f.user }}
    - group: {{ f.group }}
    - template: jinja
    - defaults:
        allows: {{ f.allows }}
{% endfor %}

{% for f in ssh.get('ssh_pubkeys_removed') %}
{{ f.name }}:
  file.absent
{% endfor %}
