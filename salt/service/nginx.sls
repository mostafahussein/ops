{% import_yaml "config/ldap.yaml" as ldap with context %}
{% import_yaml "config/kerberos.yaml" as krb with context %}
{% import_yaml "config/nginx.yaml" as nginx with context %}

service.nginx:
  service.running:
    - name: nginx
    - enable: True
    - sig: /usr/sbin/nginx
    - reload: True
    - watch:
{% for f in nginx.get('nginx_confs', ()) %}
      - file: /etc/nginx/{{ f.name }}
{% endfor %}

{% for f in nginx.get('nginx_confs', ()) %}
/etc/nginx/{{ f.name }}:
  file.managed:
    - source: {{ f.file }}
    - mode: 0644
    - user: root
    - group: root
{% endfor %}

{% for g in nginx.get('pam_ldap_config', ()) %}
/etc/ldap-{{ g.name }}.conf:
  file.managed:
    - source: salt://common/etc/ldap-tpl.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        ldapuri: {{ ldap['ldapuri'] }}
        group: {{ g.group }}
        domain: {{ krb.krb5_short }}
{% endfor %}

{% for r in nginx.get('nginx_pam_config', []) %}
/etc/pam.d/{{ r.name }}:
  file.managed:
    - source: salt://common/etc/pam.d/pam-tpl
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - context:
        sense: {{ r.sense }}
        restrict: {{ r.restrict }}
        group: {{ r.group }}
{% endfor %}

{% for r in nginx.get('nginx_pam_listfile', []) %}
/etc/nginx/{{ r.name }}:
  file.managed:
    - mode: 644
    - user: root
    - group: root
    - content: {{ r.content }}
{% endfor %}
