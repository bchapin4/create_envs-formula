# See pillar.example for details on options
#  environments:
create_envs_version: 0.1.0

####
# Default role based on ID.
# Need to move to CDNCMDB
####

{% if "saltmom" in grains['id'] %}
# Note this is the default for automated testing.
#default_role: mom
{% else %}
#default_role: base
{% endif %}

common_formulas_default_config:
  base:
    formulas:
      example_a:
        version: 1.0.0
      example_b:
        version: 1.0.0
      example_c:
        version: 1.0.0
  mom:
    formulas:
      example_a:
        version: 1.0.0
        additional_pillars:
          - groups/admins
        common_pillars:
          - groups.regular_users
      example_b:
        version: 2.0.0
        additional_pillars:
          - override_pillar_b1
  rsm_fp:
    formulas:
      example_a:
        version: 1.0.0
      example_b:
        version: 1.0.0
  rsm_tools:
    formulas:
      example_a:
        version: 1.0.0
      example_b:
        version: 1.0.0

create_envs:
  mom:
    masters:
      - mom
      - base
      - rsm_fp
  test_env:
    masters:
      - mom
      - base
      - rsm_tools
      - rsm_fp
  test_env2:
    masters:
      - mom
      - base
      - rsm_fp
    formulas:
      example_b:
        additional_pillars:
          - override_pillar_b2
      example_c:
        version: 1.0.0
        additional_pillars:
          - override_pillar
  test_env3:
    masters:
      - mom
      - base
      - rsm_fp
    formulas:
      example_b:
        version: 2.0.1
  test_env4:
    masters:
      - rsm_tools
    formulas:
      example_b:
        version: 2.0.1
  rsm_fp:
    masters:
      - mom
    formulas:
      rsm_role:
        version: 0.1.0
  development:

