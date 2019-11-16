# -*- coding: utf-8 -*-
# vim: ft=sls
{%- from tpldir + "/map.jinja" import role, create_envs_pillar with context %}

{% if role in create_envs_pillar.keys() %}

/etc/salt/minion.d/saltenv.conf:
  file.managed:
    - source: 'salt://create_envs/files/saltenv.tmpl'
    - template: jinja
    - context:
        tpldir: {{ tpldir }}
    - user: root
    - group: root
    - mode: 644
    - order: last

# Was using salt_manage.minion.delayed_restart_salt-master but didn't want the
# dependency on that formula. (since this is a "base" formula)
salt-minion_restart:
  cmd.run:
    - name: 'sleep 3 && salt-call --local service.restart salt-minion --out-file /dev/null'
    - order: last
    - bg: True
    - onchanges:
      - file: /etc/salt/minion.d/saltenv.conf

{% else %}

failure_role_none_saltenv:
  test.fail_without_changes:
    - name: "Role: {{ role }} is not in the create_envs pillar. Available Roles: {{ create_envs_pillar.keys() }}. Not updating minion_configs."
    - failhard: True

{% endif %}
