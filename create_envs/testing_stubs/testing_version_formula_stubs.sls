# -*- coding: utf-8 -*-
# vim: ft=sls

{% set tplroot = tpldir.split('/')[0] %}
{%- from tplroot + "/map.jinja" import role, common_formulas with context %}

{%- set results_formulas = {} %}

{##
merge the environment(role) formulas into the common formulas

common formulas are defined by this role's master. (i.e. mom, rsm_fp, rsm_tools etc.)

1) Get the commmon formulas for this master
2) Merge in formula values specific to this role.

merge functionality
  - merge dictionaries, overwrite lists.
  - merge second object into the original preferring second object values on conflict

i.e. for role rsm_fp
  - identifies a master of mom
  - reads in common formulas for mom (since this is the master for the rsm_fp role)
  - merge rsm_fp formulas into mom common formulas preferring values from rsm_fp

role         -- environment(role) name we are operating on
role_fomulas -- formulas object from within environment(role) pillar definition
##}

{%- macro merge_common_formulas_and_role_formulas(role, role_formulas) %}
  # merge common formulas with environment formulas.
  {%- do results_formulas.update(salt.slsutil.merge(common_formulas, role_formulas)) %}
{%- endmacro %}

{%- macro create_formulas(envname, formulas, versioned_formulas_dir) %}
  {% for formula_name, formula_options in formulas.get('formulas', {}).items() %}
    {% if formula_options['version'] %}
      {% set versioned_dir = versioned_formulas_dir + formula_name + '_' + formula_options['version'] %}
      {% set formuladir = versioned_dir + '/' + formula_name %}

      {% do salt['file.mkdir'](formuladir) %}
      {% do salt['file.touch'](formuladir + '/files') %}
      {% do salt['file.touch'](formuladir + '/init.sls') %}

      {% if formula_name == 'example_a' %}
        {% do salt['file.touch'](versioned_dir + '/' + formula_name + '.sls') %}
        {% do salt['file.touch'](versioned_dir + '/' + formula_name + '_version.sls') %}
      {% else %}
        {% do salt['file.touch'](versioned_dir + '/' + envname + '.sls') %}
      {% endif %}

      {% for additional_pillar in formula_options.get('additional_pillars', []) %}
# within salt "." represent directory so
# replace "." with "/" so we create correct directory structure
        {% set filename = versioned_dir + '/' + additional_pillar.replace('.', '/') + '.sls' %}
        {% do salt['file.makedirs'](filename) %}
        {% do salt['file.touch'](filename) %}
      {% endfor %}

      {% for common_pillar in formula_options.get('common_pillars', []) %}
# within salt "." represent directory so
# replace "." with "/" so we create correct directory structure
        {% set filename = versioned_dir + '/' + common_pillar.replace('.', '/') + '.sls' %}
        {% do salt['file.makedirs'](filename) %}
        {% do salt['file.touch'](filename) %}
      {% endfor %}
    {% endif %}
  {% endfor %}
{% endmacro %}

{% macro iterate_over_environments(versioned_formulas_dir) %}
# iterate over envname
  {% for envname, role_formulas in salt['pillar.get']('create_envs', {}).items() %}
    {% if role_formulas and role in role_formulas.get('masters', []) %}
{{ merge_common_formulas_and_role_formulas(role, role_formulas) }}
{{ create_formulas(envname, results_formulas, versioned_formulas_dir) }}
    {% endif %}
  {% endfor %}
{% endmacro %}

{% set versioned_formulas_dir = salt['pillar.get']('versioned_formulas_dir', '/srv/versioned_formulas/') %}

{% do salt['file.mkdir'](versioned_formulas_dir + '/create_envs') %}
{% do salt['file.mkdir'](versioned_formulas_dir + '/create_envs/create_envs/files') %}
{% do salt['file.touch'](versioned_formulas_dir + '/create_envs/create_envs/init.sls') %}
{% do salt['file.touch'](versioned_formulas_dir + '/create_envs/create_envs.sls') %}
{% do salt['file.touch'](versioned_formulas_dir + '/create_envs/create_envs_version.sls') %}

{{ iterate_over_environments(versioned_formulas_dir) }}
