{% import_yaml "config/hosts.yaml" as hosts with context %}

{% set ahosts = {} %}

{% for d,c in hosts.hosts.iteritems() %}
  {% import_json c as chosts %}
  {% do ahosts.update({d: chosts}) %}
{% endfor %}

{% set dshgroups = {} %}

{% for d,ds in ahosts.iteritems() %}
  {% for g,gs in ds.iteritems() %}
    {% for h,hs in gs.nodes.iteritems() %}
      {% if h != 'hosts' %}
        {% if not dshgroups.has_key(h) %}
          {% do dshgroups.update({h: []}) %}
        {% endif %}
        {% for n,ns in hs.iteritems() %}
          {% do dshgroups[h].append((n, d)) %}
        {% endfor %}
      {% endif %}
    {% endfor %}
  {% endfor %}
{% endfor %}

/etc/dsh/group:
  file.directory:
    - clean: True
    - watch:
{% for g,gs in dshgroups.iteritems() %}
        - file: /etc/dsh/group/{{ g }}
{% endfor %}

{% for g,gs in dshgroups.iteritems() %}
  {% if gs %}
/etc/dsh/group/{{ g }}:
  file.managed:
    - source: salt://etc/dsh/group/group
    - template: jinja
    - makedirs: True
    - defaults:
        vars:
    {% for n,d in gs|sort %}
          - {{ n }}.{{ d }}
    {% endfor %}
  {% endif %}
{% endfor %}
