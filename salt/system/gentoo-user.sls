{% import_yaml "config/group.yaml" as group with context %}

# @todo passwd/group/shadow/gshadow

user.root:
  user.present:
    - name: root
    - shell: /bin/bash
    - home: /root
    - uid: 0
    - gid: 0
    - groups:
      - root
      - bin
      - daemon
      - sys
      - adm
      - disk
      - wheel
      - floppy
      - dialout
      - tape
      - video

{% for s in group.get('groups', []) %}
group.{{ s.name }}:
  group.present:
    - name: {{ s.name }}
    - gid: {{ s.gid }}
{% endfor %}
