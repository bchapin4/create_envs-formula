# -*- coding: utf-8 -*-
# vim: ft=sls
{%- from tpldir + "/map.jinja" import role with context %}

test:
  test.nop:
  - Version: create_envs version {{ salt['pillar.get']('create_envs_version', 'unset') }}

include:
{%- if 'mom' in role or 'rsm' in role %}
  {%- if 'rsm' in role %}
  - {{ tpldir }}.pull_versioned_formulas
  {%- endif %}
  - {{ tpldir }}.create_role_symlinks
  - {{ tpldir }}.environments_conf
  - {{ tpldir }}.create_tops
{%- endif %}
  - {{ tpldir }}.minion_config
