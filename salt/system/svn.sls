{% import_yaml "config/svn.yaml" as svn with context %}

{% if svn.dirs and svn.dirs is iterable %}
  {% for d in svn.dirs %}
    # can't set locale for svn status, so use cmd.run_all
    {# set svn_status = salt['svn.status'](d, None, None, None, None, '--config-dir', '/tmp/.subversion')|replace('       ', ' ') #}
    {% set svn_status = salt['cmd.run_all'](' '.join(('svn status', '--config-dir /tmp/.subversion', d)),
                                            env={'LC_ALL': 'en_US.UTF-8'}) %}
    {% if svn_status.get('retcode') != 0 %}
      {% set svn_result = "`svn status %s' failed w/ %d"|format(d, svn_status.get('retcode')) %}
    {% else %}
      {% if svn_status.get('stderr') %}
        {% set svn_result = "`svn status %s' return error"|format(d) %}
      {% elif svn_status.get('stdout') %}
        {% set svn_result = svn_status.get('stdout')|replace('       ', ' ') %}
      {% else %}
        {% set svn_result = "" %}
      {% endif %}
    {% endif %}
    {% if svn_result %}
svn.status({{ d }}):
  cmd.run:
    - name: "echo {{ svn_result.split('\n')|join('|') }}"
    {% endif %}
  {% endfor %}
{% endif %}

{% set groups = {} %}
{% for g in salt['group.getent']() %}
  {% do groups.update({g['gid']: g }) %}
{% endfor %}

{% for user in svn.users|default(('root',)) %}
  {% set userinfo = salt['user.info'](user) %}
  {% if not userinfo %}
    {% continue %}
  {% endif %}
  {% set group = groups[userinfo['gid']]['name'] %}
  {% set svndir = '/'.join((userinfo['home'], '.subversion')) %}
  {% if salt['file.directory_exists'](svndir) %}
    {% for f in ('config', 'servers') %}
{{ svndir }}/{{ f }}:
  file.managed:
    - user: {{ user }}
    - group: {{ group }}
    - mode: 644
    - source:
      - salt://etc/subversion/{{ f }}
      - salt://common/etc/subversion/{{ f }}
    {% endfor %}

    {% for f in salt['file.find']('/'.join((svndir, 'auth')), type='f') %}
      {% if salt['file.contains'](f, 'password') %}
svn.auth.{{ f }}:
  cmd.run:
    - name: "echo '{{ f }} contains password field, please delete it.'"
      {% endif %}
    {% endfor %}
  {% endif %}
{% endfor %}
