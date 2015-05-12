{% import_yaml "config/scms.yaml" as scms with context %}

{% set svn_dirs = [] %}
{% set git_dirs = [] %}
{% if scms.dirs is defined and scms.dirs is iterable %}
  {% for d in scms.dirs %}
    {% if d.type == "svn" %}
      {% do svn_dirs.append(d.name) %}
    {% elif d.type == "git" %}
      {% do git_dirs.append(d.name) %}
    {% else %}
scms.dirs.{{ d.name }}:
  cmd.run:
    - name: "echo 'unknown type {{ d.type }} defined for {{ d.name }}'"
    {% endif %}
  {% endfor %}
{% endif %}

{% for d in svn_dirs %}
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

{% set groups = {} %}
{% for g in salt['group.getent']() %}
  {% do groups.update({g['gid']: g }) %}
{% endfor %}

{% for user in scms.svn_users|default(('root',)) %}
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

{% for d in git_dirs %}
  {% set git_base_cmd = 'git --work-tree=%s --git-dir=%s/.git'|format(d, d) %}

  {# set git_cmd = 'git -C %s status -s'|format(d) #}
  {% set git_cmd = '%s status -s'|format(git_base_cmd) %}
  {% set git_status = salt['cmd.run_all'](git_cmd, env={'LC_ALL': 'en_US.UTF-8'}) %}
  {% if git_status.get('retcode') != 0 %}
    {% set git_result = "`%s' failed w/ %d"|format(git_cmd, git_status.get('retcode')) %}
  {% else %}
    {% if git_status.get('stderr') %}
      {% set git_result = "`%s' return error '%s'"|format(git_cmd, git_status.get('stderr')) %}
    {% elif git_status.get('stdout') %}
      {% set git_result = git_status.get('stdout') %}
    {% else %}
      {% set git_result = "" %}
    {% endif %}
  {% endif %}
  {% if git_result %}
git.status.{{ d }}:
  cmd.run:
    - name: "echo {{ git_result.split('\n')|join(',') }}"
  {% endif %}

  {# Precondition: local branch and remote branch have same name #}
  {% set get_head_name_cmd = '%s rev-parse --abbrev-ref HEAD'|format(git_base_cmd) %}
  {% set head_name = salt['cmd.run_all'](get_head_name_cmd, env={'LC_ALL': 'en_US.UTF-8'}).get('stdout') %}
  {% set git_cmd = '%s rev-list --left-right --count origin/%s...HEAD'|format(git_base_cmd, head_name) %}
  {% set git_status = salt['cmd.run_all'](git_cmd, env={'LC_ALL': 'en_US.UTF-8'}) %}
  {% if git_status.get('retcode') != 0 %}
    {% set git_result = "`%s' failed w/ %d"|format(git_cmd, git_status.get('retcode')) %}
  {% else %}
    {% if git_status.get('stderr') %}
      {% set git_result = "`%s' return error '%s'"|format(git_cmd, git_status.get('stderr')) %}
    {% elif git_status.get('stdout') %}
      {% set out = git_status.get('stdout') %}
      {% set git_behind, git_ahead = out.split() %}
      {% set out_a, out_b = ('', '') %}
      {% if git_behind != '0' %}
        {% set out_b = "HEAD is behind of origin/master by " ~ git_behind ~ " commits" %}
      {% endif %}
      {% if git_ahead != '0' %}
        {% set out_a = "HEAD is ahead of origin/master by " ~ git_ahead ~ " commits" %}
      {% endif %}
      {% set git_result = out_a ~ (';' if (out_a and out_b) else '') ~ out_b %}
    {% else %}
      {% set git_result = "" %}
    {% endif %}
  {% endif %}
  {% if git_result %}
git.sync.{{ d }}:
  cmd.run:
    - name: "echo {{ git_result }}"
  {% endif %}
{% endfor %}

{% if scms.git_files is defined and scms.git_files is iterable %}
  {% for f in scms.git_files %}
{{ f.name }}:
    {% if f.source is not defined %}
  file.absent
    {% else %}
  file.managed:
    - source: {{ f.source }}
    - user: root
    - group: root
    - mode: {{ f.mode|default('0644') }}
    - template: jinja
    {% endif %}
  {% endfor %}
{% endif %}
