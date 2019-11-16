# -*- coding: utf-8 -*-
# vim: ft=sls
{%- from tpldir + "/map.jinja" import role with context %}

{% for envname, formulas in salt['pillar.get']('create_envs', {}).items() %}

  # If this environment is applicable to the role on this box, otherwise skip
  {% if formulas is not none and role in formulas.get('masters', [])  %}

/srv/pillar/{{ envname }}/top.sls:
  file.managed:
    - source: 'salt://create_envs/files/top.tmpl'
    - template: jinja
    - user: cdnsalt
    - group: cdnsalt
    - mode: 644
    - context:
        environ: {{ envname }}
        tpldir: {{ tpldir }}

  {% endif %}

{% endfor %}
