# -*- coding: utf-8 -*-
# vim: ft=sls

{%- from tpldir + "/map.jinja" import role, common_formulas, BASE_PILLAR_DIR, BASE_FORMULAS_DIR, BASE_VERSIONED_FORMULA_DIR with context %}

{%- set results_formulas = {} %}
{%- set dir_list = [] %}
{%- set file_exists_list = [] %}

{## MACROS ##}

{##
Test for file existance

results -- result string to add to
name    -- file to check
##}

{%- macro test_file_existance(name) %}
  {%- if name in file_exists_list %}
    {%- do file_exists_list.append(name) %}

{{name}}_test_file_existance:
  file.exists:
    - name: "File does not exist: " + {{ name }}
    - failhard: True

  {%- endif %}
{%- endmacro %}

{##
create symlink name -> target

list    -- list of links created (will be added to)
name    -- file to link to
target  -- target file name
namedir -- directory for creation requirement
##}

{%- macro create_symlink(list, name, target, ignore_missing=False) %}

  {%- do list.append(name) %}

create_symlink_{{ name }}:
  file.symlink:
    - name: {{ name }}
    - target: {{ target }}
    - user: cdnsalt
    - group: cdnsalt
    - makedirs: True
  {%- if ignore_missing %}
    - onlyif:
      - test -e {{ target }}
  {%- endif %}

{%- endmacro %}

{##
remove a file

filename -- file to remove
##}

{%- macro rm_files(name) %}

rm_{{ name }}:
  file.absent:
    - name: {{ name }}

{%- endmacro %}

{##
clean up any symlinks from an environment(role) that are not currently defined in the pillar
(these could be put in place by previous runs, or by hand)
environments are only controlled through this state

envname       -- environment(role) to clean up
formula_links -- list of formula links created by this state run
pillar_links  -- list of pillar links created by this state run
##}

{%- macro cleanup_old_role_files(envname, formula_links, pillar_links) %}

  {%- set pillardir = BASE_PILLAR_DIR ~ envname ~ '/' %}
  {%- set formuladir = BASE_FORMULAS_DIR ~ envname ~ '/*' %}
  {%- do pillar_links.append(pillardir ~ 'top.sls') %}

  {%- for filename in salt['file.find'](pillardir, type='f') %}
    {%- if filename not in pillar_links %}
{{ rm_files(filename) }}
    {%- endif %}
  {%- endfor %}

  {%- for filename in salt['file.find'](formuladir, type='d', maxdepth=0) %}
    {%- if filename not in formula_links %}
{{ rm_files(filename) }}
    {%- endif %}
  {%- endfor %}

{%- endmacro %}

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

{##
iterate over environment(role) configuration
  - validate defined versioned_formulas exists
  - create directories (formulas and pillars)
  - create symlinks within formulas and pillar (create_envs special cased)

envname       -- environment(role) to clean up
formulas      -- formula definition for this environment(role)
formula_links -- list of formula links created by this state run
pillar_links  -- list of pillar links created by this state run
##}

{%- macro create_role_envs(envname, formulas, formula_links, pillar_links) %}

# Iterate over roles information
  {%- for formula_name, formula_options in formulas.get('formulas', {}).items() %}
    {%- if formula_options['version'] %}

# link formula
      {%- set formulabase = BASE_FORMULAS_DIR ~ envname %}
      {%- set formuladir = formulabase ~ '/' ~ formula_name %}
      {%- set targetdir = BASE_VERSIONED_FORMULA_DIR ~ formula_name ~ '_' ~ formula_options['version'] ~ '/' ~ formula_name %}
      {%- do formula_links.append(formuladir) %}

{{ test_file_existance(targetdir) }}

# symlink <formula> -> versioned_formula/<formula>

{{ create_symlink(formula_links, formuladir, targetdir) }}

      {%- set pillardir = BASE_PILLAR_DIR + envname %}
      {%- set targetdir = BASE_VERSIONED_FORMULA_DIR + formula_name + '_' + formula_options['version'] + '/' %}

# link <formula>_version.sls
      {%- set pillar_link = pillardir + '/' + formula_name + '_version.sls' %}
      {%- set target = targetdir + formula_name + '_version.sls' %}

{{ create_symlink(pillar_links, pillar_link, target) }}

# link pillars
      {%- set pillar_link = pillardir + '/' + formula_name + '.sls' %}
      {%- set env_pillar = targetdir + envname + '.sls' %}
      {%- set default_pillar = targetdir + formula_name + '.sls' %}

# if <envname>.sls
#   symlink <formulaname>.sls -> <envname>.sls
# else
#   symlink <formulaname>.sls -> <formulaname>.sls
      {%- if salt['file.file_exists'](env_pillar) %}
{{ create_symlink(pillar_links, pillar_link, env_pillar) }}
      {%- else %}
{{ create_symlink(pillar_links, pillar_link, default_pillar, True) }}
      {%- endif %}

# symlink any additional pillars
# symlink <formulaname>_<additional_pillar>.sls -> <additional_pillar>.sls
      {%- for additional_pillar in formula_options.get('additional_pillars', []) %}

# within salt "." represent directory so
# replace "." with "/" so we create correct directory structure
        {%- set additional_pillar_replaced = additional_pillar | replace(".", "/") %}
        {%- set pillar_link = pillardir + '/' + formula_name + '_' + additional_pillar_replaced + '.sls' %}
        {%- set target = targetdir + additional_pillar_replaced + '.sls' %}

{{ create_symlink(pillar_links, pillar_link, target) }}

      {%- endfor %}

# symlink any common pillars
# symlink <formulaname>_<common_pillar>.sls -> <common_pillar>.sls
      {%- for common_pillar in formula_options.get('common_pillars', []) %}

# within salt "." represent directory so
# replace "." with "/" so we create correct directory structure
          {%- set common_pillar = common_pillar.replace(".", "/") %}
          {%- set pillar_link = pillardir + '/' + formula_name + '_' + common_pillar + '.sls' %}
          {%- set target = targetdir + common_pillar + '.sls' %}

{{ create_symlink(pillar_links, pillar_link, target, True) }}

      {%- endfor %}

    {%- else %}

failure_{{ envname }}_{{ formula_name }}_noversion:
  test.file_without_changes:
    name: 'create_envs must either define a version or absent for each formula'
    failhard: True

    {%- endif %}
  {%- endfor %}
{%- endmacro %}

{##
iterate over all the environments(roles)
  - create directories formulas/<environment> and pillar/<environment>
  - create deploy_location and create_envs in each environment
  - cleanup old files from each environment
  - remove the pillar and formula directories if no longer defined in this environment(role)

no args
##}

{%- macro iterate_over_environments() %}

# list of formula links created by this state run
  {%- set formula_links = [] %}
# list of pillar links created by this state run
  {%- set pillar_links = [] %}

# iterate over envname
  {%- for envname, role_formulas in salt['pillar.get']('create_envs', {}).items() %}
    {%- if role_formulas is not none and role in role_formulas.get('masters', []) %}

{{ merge_common_formulas_and_role_formulas(role, role_formulas) }}

      {%- set formuladir = BASE_FORMULAS_DIR + envname %}
      {%- set pillardir = BASE_PILLAR_DIR + envname %}

      {%- set pillar_link = pillardir + '/create_envs.sls' %}
      {%- set target = '/srv/versioned_formulas/create_envs/create_envs.sls' %}
{{ create_symlink(pillar_links, pillar_link, target) }}

      {%- set pillar_link = pillardir + '/create_envs_version.sls' %}
      {%- set target = '/srv/versioned_formulas/create_envs/create_envs_version.sls' %}
{{ create_symlink(pillar_links, pillar_link, target) }}

      {%- set formula_link = formuladir + '/create_envs' %}
      {%- set target = '/srv/versioned_formulas/create_envs/create_envs' %}
{{ create_symlink(formula_links, formula_link, target) }}

{{ create_role_envs(envname, results_formulas, formula_links, pillar_links) }}

{{ cleanup_old_role_files(envname, formula_links, pillar_links) }}

    {%- else %}

# remove the pillar and formula directories if no longer defined in this environment(role)
{{ rm_files(BASE_PILLAR_DIR + envname) }}
{{ rm_files(BASE_FORMULAS_DIR + envname) }}

    {%- endif %}
  {%- endfor %}
{%- endmacro %}

{{ iterate_over_environments() }}
