{% import_yaml "config/users.yaml" as users with context %}

{% if users.users is defined %}
  {% for s in users.get('users', ()) %}
user.{{ s.name }}:
  user.present:
    - name: {{ s.name }}
    - uid: {{ s.uid }}
    - gid: {{ s.gid }}
    - home: {{ s.home }}
    - shell: {{ s.shell }}
    - groups:
    {% for g in s.get('groups', ()) %}
      - {{ g }}
    {% endfor %}
  {% endfor %}
{% endif %}

{% if users.groups is defined %}
  {% for s in users.get('groups', ()) %}
group.{{ s.name }}:
  group.present:
    - name: {{ s.name }}
    - gid: {{ s.uid }}
  {% endfor %}
{% endif %}
