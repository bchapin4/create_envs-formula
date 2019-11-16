# -*- coding: utf-8 -*-
# vim: ft=sls
{%- from tpldir + "/map.jinja" import role with context %}

{% if role is not none %}

/etc/salt/master.d/environments.conf:
  file.managed:
    - source: 'salt://create_envs/files/environment.tmpl'
    - template: jinja
    - user: cdnsalt
    - group: cdnsalt
    - mode: 644
    - order: last

# Was using salt_manage.master.delayed_restart_salt-master but didn't want the
# dependency on that formula. (since this is a "base" formula)
salt-master_restart:
  cmd.run:
    - name: 'sleep 3 && salt-call --local service.restart salt-master --out-file /dev/null'
    - order: last
    - bg: True
    - onchanges:
      - file: /etc/salt/master.d/environments.conf

{% else %}

failure_role_none_environments:
  test.fail_without_changes:
    - name: "Role is set to None, not updating environments.conf"
    - failhard: True

{% endif %}
