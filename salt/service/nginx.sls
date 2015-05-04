{% import_yaml "common/config/packages.yaml" as pkgs with context %}
{% import_yaml "config/ldap.yaml" as ldap with context %}
{% import_yaml "config/kerberos.yaml" as krb with context %}
{% import_yaml "config/nginx.yaml" as nginx with context %}

service.nginx:
{% if nginx.nginx_confs|default(False) %}
  {% if nginx.pkg_installed|default(True) %}
  pkg.installed:
    - name: {{ pkgs.nginx | default('nginx') }}
    - refresh: False
  {% endif %}
  service.running:
    - name: nginx
    - enable: True
    - sig: /usr/sbin/nginx
    - reload: True
    - watch:
  {% for f in nginx.get('nginx_confs', ()) %}
      - file: /etc/nginx/{{ f.name }}
  {% endfor %}

/etc/nginx:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - clean: True
    - exclude_pat: "E@^(scgi|fastcgi|proxy|uwsgi)_params|mime.types|fastcgi.conf|naxsi_core.rules$"
    - require:
  {% for f in nginx.get('nginx_confs', ()) %}
      - file: /etc/nginx/{{ f.name }}
  {% endfor %}
  {% for r in nginx.get('nginx_pam_listfile', {}) %}
      - file: /etc/nginx/{{ r.name }}
  {% endfor %}

  {% for f in nginx.get('nginx_confs', ()) %}
/etc/nginx/{{ f.name }}:
    {% if f.source is defined %}
  file.managed:
    - source: {{ f.source }}
    - mode: {{ f.mode|default('0644') }}
    - template: jinja
      {% if f.rlimit_nofile is defined %}
    - defaults:
        rlimit_nofile: {{ f.rlimit_nofile }}
      {% endif %}
    {% elif f.target is defined %}
  file.symlink:
    - target: {{ f.target }}
    {% endif %}
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

  {% for r in nginx.get('nginx_pam_listfile', {}) %}
/etc/nginx/{{ r.name }}:
  file.managed:
    - source: salt://common/etc/nginx/pam_listfile
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        users: {{ r.content }}
  {% endfor %}

  {% if grains['os'] == "Gentoo" %}
/var/log/nginx:
  file.directory:
    - user: nginx
    - group: nginx
    - mode: 750
    - makedirs: True
  {% endif %}

{% else %}
  service.dead:
    - name: nginx
    - enable: False
    - sig: /usr/sbin/nginx
{% endif %}
