{% import_yaml "config/alias.yaml" as alias with context %}

{% for f in alias.get('aliases', ()) %}
alias.{{ f.name }}:
  alias.present:
    - name: {{ f.name }}
    - target: {{ f.target }}
{% endfor %}
