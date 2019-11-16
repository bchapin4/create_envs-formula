# -*- coding: utf-8 -*-
# vim: ft=sls
{%- from tpldir + "/map.jinja" import role, common_formulas with context %}

# List of formulas synced during this run.
#   - build the list as we go
#   - use the list at the end to clean up any formulas not
#     created during this run
{% set formula_links = [] %}

{% set create_envs_formuladir = '/srv/versioned_formulas/create_envs' %}
{% do formula_links.append(create_envs_formuladir) %}

# Sync create_envs formula MOM -> RSM
#   this is outside the normal loop because is unversioned and thus has different
#   params

sync_{{ create_envs_formuladir }}:
  file.recurse:
    - name: {{ create_envs_formuladir }}
    - source: 'salt://create_envs'
    - user: cdnsalt
    - group: cdnsalt
    - dir_mode: 755
    - file_mode: 644
    - include_empty: True
    - keep_symlinks: True
    - failhard: True

# Macro to sync a specific version of a formula from the Master of Masters down to the RSM
#
# envname       -- environment(role) to clean up
# formulas      -- formula definition for this environment(role)
# formula_links -- list of formula links created by this state run
# pillar_links  -- list of pillar links created by this state run
# versioned_formulas_dir -- base directory for versioned formulas
{%- macro sync_formulas(envname, formulas, formula_links, versioned_formulas_dir) %}

  {% set formuladir = 'unset' %}

  {% for formula_name, formula_options in formulas.get('formulas', {}).items() %}

    {% if formula_options.version is defined %}

      {% set formuladir = versioned_formulas_dir ~ formula_name ~ '_' ~ formula_options.version %}
      {% do formula_links.append(formuladir) %}

sync_{{ envname }}_{{ formuladir }}_{{ formula_name }}_{{ formula_options.version }}:
  file.recurse:
    - name: {{ formuladir }}
    - source: 'salt://{{ formula_name }}_{{ formula_options.version }}'
    - user: cdnsalt
    - group: cdnsalt
    - dir_mode: 755
    - file_mode: 644
    - include_empty: True
    - keep_symlinks: True
    - failhard: True

    {% endif %}

  {% endfor %}

{%- endmacro %}

# This file follows the same pattern as the config.sls. See that file for any detailed comments.
{% set versioned_formulas_dir = '/srv/versioned_formulas/' %}
{% do formula_links.append(versioned_formulas_dir) %}

# pull down the role formulas - MOM -> RSM
{% for envname, formulas in salt['pillar.get']('create_envs', {}).items() %}

  # If this environment(role) is applicable to the role on this box, sync the formulas
  #    otherwise skip
  {% if formulas is not none and role in formulas.get('masters', []) %}

    {{ sync_formulas(envname, formulas, formula_links, versioned_formulas_dir) }}

  {% endif %}

{% endfor %}

{{ sync_formulas(role, common_formulas, formula_links, versioned_formulas_dir) }}

# cleanup any old environments(roles) that are no longer applicable on RSM's only. (not MOM's)
{% if role != 'mom' %}

  {% for filename in salt.file.find(versioned_formulas_dir, type='d', maxdepth=1) %}

    {% if filename not in formula_links %}

rm_{{ filename }}:
  file.absent:
    - name: {{ filename }}

    {% endif %}

  {% endfor %}

{% endif %}
