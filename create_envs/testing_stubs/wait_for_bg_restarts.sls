# -*- coding: utf-8 -*-
# vim: ft=sls

include:
  - create_envs.environments_conf
  - create_envs.minion_config

wait_for_bg_restarts:
  cmd.run:
    - name: "sleep 60"
    - order: last
    - onchanges:
      - cmd: salt-master_restart
      - cmd: salt-minion_restart
