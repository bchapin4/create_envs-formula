# Table of Contents
- [Overview](#overview)
- [State Dependency](#state-dependency)
- [Available States ](#available-states-)
- [Pillar Data](#pillar-data)
- [Example state execution](#example-state-execution)
- [Interfaces](#interfaces)
- [Common Errors](#common-errors)
- [Deployment](#deployment)
- [Testing](#testing)
- [External Libraries ](#external-libraries-)
- [Reference Pages](#reference-pages)

# Overview
Salt file to create the salt [Environments](http://gtarch.level3.com/display/CD/Saltstack+Formula+Integration#SaltstackFormulaIntegration-Environments)

* Creates Environments based on a pillar file
    * *Each server role will have its own "Environment"*
* Assigns versioned formulas to each Environment
* Creates a master config that recognizes all Environments
* ***The minion_saltenv formula assigns each server to an Environment based on role***

***create_envs state should be applied to all salt-masters, syndics and minions***

On a Master of Masters:

* Create all formula and pillar symlinks
* Create top files for all formula pillars
* Populate environments.conf
* Populate minion configs for saltenv and pillarenv

On a Syndic:

* Pull down versioned formulas from master
* Create all formula and pillar symlinks
* Create top files for all formula pillars
* Populate environments.conf
* Populate minion configs for saltenv and pillarenv

On a minion:

* Populate minion configs for saltenv and pillarenv

## Definitions

* **mom**
  * Master of Masters

* **rsm**
  * Regional Salt Masters

* **common formulas**
  * Formulas that are used as building blocks for other formulas
  * i.e. firewalld is used by multiple formulas
  * defined by master (mom, rsm_tools, etc) and available for use by any minion to that master
  * defined in the common_formulas_default_config section of the pillar

* **role formulas**
  * Formulas that are applied to a role
  * makes use of any common formulas it needs.
  * typically defined per role in the create_envs section of the pillar

## Future State
* The create_envs pillar is currently defined in this project, a better place would be in some [CMDB](https://searchdatacenter.techtarget.com/definition/configuration-management-database) instance with apis to pull as an [external pillar](https://docs.saltstack.com/en/master/topics/development/modules/external_pillars.html).

# State Dependency
*This state depends on the following states or formulas*

* ***None***

# Available States

- [create_envs](#create_envs)
- [create_envs.create_role_symlinks](#create_envscreate_role_symlinks)
- [create_envs.create_deploy_location_tmpl](#create_envscreate_deploy_location_tmpl)
- [create_envs.create_tops](#create_envscreate_tops)
- [create_envs.environment_conf](#create_envsenvironment_conf)
- [create_envs.minion_config](#create_envsminion_config)
- [create_envs.pull_versioned_formulas](#create_envspull_versioned_formulas)

**Testing Only**

- [create_envs.testing_stubs.testing_version_formula_stubs](#create_envstesting_stubstesting_version_formula_stubs)
- [create_envs.testing_stubs.wait_for_bg_restarts](#create_envstesting_stubswait_for_bg_restarts)

## create_envs

* Creates /srv/formulas directory structure
* Creates /srv/pillar directory structure
* Creates a environment.conf master config file
* Cleans up any symlinks that are no longer defined in the pillar

***Validates:***
* Each formula has a version attached
* Each formula version exists on the server
* All defined pillars exist

## create_envs\.create_role_symlinks

* Loops over Environments and formulas
	* Symlinks from versioned\_formulas into formulas/***ENV***/
	* Symlinks from versioned\_formulas into pillar/***ENV***/
* Creates *ENV* top file in salt/*ENV*/top.sls
* Removes any extraneous links from previous runs.
  * i.e. if we used to have a pillar1 override in an old version, but do not anymore, then cleans that up.

## create_envs.create_deploy_location_tmpl

* Run only on the master of masters. (MOM)
* Create a deploy location template on the salt file server with the deploy_location set to a static value. (lab, prod, dev etc.)
* Original value comes from the master of masters config.
* RSM's then pull down this static template file with deploy_location populated.
* This template then populates the /etc/salt/minion.d/deploy_location.conf file on all the minions.
* Having the deploy_location in the minion configs allows us to use deploy location in pillar files.
  * ***Pillar values cannot depend on other pillar values, but they can be set by config values***

## create_envs.create_tops

* Create a pillar top file for each environment based on the pillar files defined in the create_envs pillar

## create_envs.environment_conf

* Creates a master config that recognizes all Environments
  * Based on the Environments defined in the pillar
* Uses the environments.tmpl to generate file
* Restarts the Master if that environment.conf file changes
  * delayed 3 seconds after job

## create_envs.minion_config

* Sets the minion saltenv and saltpillar to point to correct role
* Sets the deploy_location minion config (lab, prod, dev, etc.)
* Restarts the salt minion on changes
  * delayed 3 seconds after job

## create_envs.pull_versioned_formulas

* Pulls all applicable versioned formulas to an RSM from the MOM

## create_envs.testing_stubs.testing_version_formula_stubs

* This state is only used for automated testing.
* Based on the create_envs.sls pillar file it sets up stubs for
  * /srv/versioned_formulas directory
  * Versioned formula directories
  * Empty init.sls in each formula
  * Empty pillar files
* The directory structure allows us to validate the pillar file
  * Is formatted properly
  * Has all necessary values populated
* If the pillar is improperly formatted, then the test phase of CI/CD will fail.

## create_envs.testing_stubs.wait_for_bg_restarts

* This state is only used for automated testing.
* Simple sleep state that waits on salt-minion and salt-master to restart.
* The restarts are detached bg processes, and the connection to the container must stay open for them to complete.

# Pillar Data

Pillar options allow you to:

* Create a new environment
* Assign a particular version of a formula to an environment
* Define pillar data per environment

Notes on ***masters***:

* Each environment will have a list of masters.
* This environment will only be created on that master for the minions connected to that master
* *Note:* if you want to run a formula on an rsm itself then it must be assigned to the mom
  * the rsms are minions to the mom

common_formulas_default_config:

* Common formulas are formulas available to every environment(role) on a particular master.
* This is to eliminate defining common things like users or logrotate for every environment(role) on the server.
* Example
  * if the users formula is defined in common_formulas_default_config:mom:formulas
  * any minion of the mom could include that formula (or run that formula independently)
  * it does not need to be defined in the environment(role) section of create_envs

additional_pillars:

* This is a list of any pillars you want to define outside of the defaults: \<formula_name>.sls or \<environment_name>.sls
* Additional pillars can be defined in either of the following sections:
  * ***common_formulas_default_config:\<master>:formulas:\<formula_name>***
  * ***create_envs:\<environment>:formulas:\<formula_name>***
* It always prefers the additional_pillars defined in the create_envs section if defined in both places
* If pillars are in a directory structure they may be defined with "/" or "." denoting directories.
  * pillar file lives in users-formula/pillar/groups/cdnsalt.sls

```yaml
create_envs:
  mom:
    formulas:
      users:
        additional_pillars:
          - groups.cdnsalt
```

common_pillars:

* This is a list of any pillars you want to define outside of the defaults: \<formula_name>.sls or \<environment_name>.sls
* Common pillars are for any additional pillars that should be used in all child environments
* Common pillars should be defined in the following section:
  * ***common_formulas_default_config:\<master>:formulas:\<formula_name>***
* If pillars are in a directory structure they may be defined with "/" or "." denoting directories.
  * pillar file lives in users-formula/pillar/groups/cdnsalt.sls

```yaml
common_formulas_default_config:
  mom:
    formulas:
      users:
        common_pillars:
          - groups.cdnsalt
```

Merging common formulas with role specific formulas

* All roles get the common formulas for their master type
  * i.e. rsm's are minions of mom, so they have access to all mom common formulas
* Merging always prefers values in the role formulas if they exist (otherwise use values from common formulas)
* When defining additional formulas or any other list
  * if a value is defined in the role formula it will overwrite the entire list
  * i.e.
    * if in the common formulas additional pillars contains ***pillar1***
    * and in role formulas additional pillars contains ***pillar2***
    * the resulting formula will get only additional pillars of ***pillar2***

**Example Pillar**
```yaml
# -*- coding: utf-8 -*-
# vim: ft=sls

####
# Default role based on ID.
# Need to move completely to CDNCMDB
#
# if salt_role defined in cdncmdb then will use that value
####
{% if "mom" in grains['id'] %}
default_role: mom
{% elif "rsm" in grains['id'] %}
default_role: rsm_tools
{% else %}
default_role: min_tools
{% endif %}

# no need to define create_envs in common_formulas

# mom = Master of Masters (includes local master cache for all job information)
# rsm = Regional Salt Master (with syndic and master processes)
# min = minion (no master capability)

# These are the common formulas available for any minions of this master type.
# i.e. any minion of the mom
common_formulas_default_config:
  # role
  mom:
    # define common formulas available on this master
    # can be overridden in the roles below in create_envs section
    formulas:
      # formula name
      firewalld:
        # formula version
        version: 0.1.0
      logrotate:
        version: 0.1.0
      postgres:
        version: 0.1.0
      salt_manage:
        version: 0.1.0
        # any additional pillars for this formula
        additional_pillars:
          - salt_manage_pillar2
      sudoers:
        version: 0.1.0
      users:
        version: 0.1.0
        # can include a list of common pillars
        common_pillars:
          - users
          - groups
        # can include a list of additional pillars.
        additional_pillars:
          - groups.cdnsalt
          - groups.na_sysadmin
  rsm_fp:
    formulas:
      logrotate:
        version: 0.1.0
      users:
        version: 0.1.0
  rsm_tools:
    formulas:
      logrotate:
        version: 0.1.0
      users:
        version: 0.1.0
  rsm_tools_public:
    formulas:
      logrotate:
        version: 0.1.0
      users:
        version: 0.1.0

create_envs:
  mom:
    # choose the master(s) for this role
    # Note: is a list
    masters:
      - mom
    # define any additional formulas to add to common_formulas from mom
    formulas:
      local_master_cache:
        version: 0.1.0
  rsm_tools:
    masters:
      - mom
    # define any additional formulas to add to common_formulas from mom
    # inherits common_formulas from master
    formulas:
      rsm_role:
        version: 0.1.0
      firewalld:
        # override the version from common formulas to use different version
        version: 0.1.1
  rsm_tools_public:
    masters:
      - mom
    # define any additional formulas to add to common_formulas from mom
    # inherits common_formulas from master
    formulas:
      rsm_role:
        version: 0.1.0
  rsm_fp:
    masters:
      - mom
    formulas:
      rsm_role:
        # choose the version you want
        version: 0.1.1
      salt_manage:
        # use default version from common formulas
        ## Override salt_manage_pillar2 from common formulas
        additional_pillars:
          - salt_manage_alt_pillar2
  min_tools:
    # this role can be applied to servers that are minions of either
    # - rsm_tools - in the IDC
    # - rsm_tools_public - out in public IP space
    masters:
      - rsm_tools
      - rsm_tools_public
  min_fp_ga:
    masters:
      - rsm_fp
  min_wowza_ga:
    masters:
      - rsm_aos
```

# Example state execution

## Example deployed directory layout
*Assumed already deployed from each of the formula projects*

* /srv/salt/versioned_formulas

```bash
/srv/versioned_formulas/
├── example_a_1.0.0
│   ├── example_a
│   │   └── init.sls
│   └── example_a.sls
├── example_b_2.0.0
│   ├── example_b
│   │   └── init.sls
│   └── example_b.sls
├── example_b_2.0.1
│   ├── example_b
│   │   └── init.sls
│   ├── example_b.sls
│   └── test_env3.sls
└── example_c_1.0.0
    ├── example_c
    │   └── init.sls
    ├── example_c.sls
    └── override_pillar.sls

8 directories, 10 files
```

## Example Pillar

```yaml
# See pillar.example for details on options
#  environments:
create_envs_version: 0.1.0

create_envs:
  test_env:
    example_a:
      version: 1.0.0
    example_b:
      version: 2.0.0
  test_env2:
    example_b:
      version: 2.0.0
    example_c:
      version: 1.0.0
      pillar: override_pillar.sls
  test_env3:
    example_b:
      version: 2.0.1
    example_c:
      absent: True
```

## Created directory layout
***The example pillar above creates the formulas and pillar directories below***

* /srv/salt/formulas

```bash
/srv/formulas
├── test_env
│   ├── example_a -> /srv/versioned_formulas/example_a_1.0.0/example_a
│   └── example_b -> /srv/versioned_formulas/example_b_2.0.0/example_b
├── test_env2
│   ├── example_b -> /srv/versioned_formulas/example_b_2.0.0/example_b
│   └── example_c -> /srv/versioned_formulas/example_c_1.0.0/example_c
└── test_env3
    └── example_b -> /srv/versioned_formulas/example_b_2.0.1/example_b

8 directories, 0 files
```

* /srv/salt/pillar

```bash
pillar
├── test_env
│   ├── example_a.sls -> /srv/versioned_formulas/example_a_1.0.0/example_a.sls
│   ├── example_b.sls -> /srv/versioned_formulas/example_b_2.0.0/example_b.sls
│   └── top.sls
├── test_env2
│   ├── example_b.sls -> /srv/versioned_formulas/example_b_2.0.0/example_b.sls
│   ├── example_c.sls -> /srv/versioned_formulas/example_c_1.0.0/override_pillar.sls
│   └── top.sls
└── test_env3
    ├── example_b.sls -> /srv/versioned_formulas/example_b_2.0.1/test_env3.sls
    └── top.sls

3 directories, 8 files
```

# Interfaces

## Salt Examples

* Render jinja

```bash
salt saltmompri slsutil.renderer /srv/formulas/create_envs/config.sls 'jinja'
```

* Show state

```bash
salt saltmompri state.show_sls create_envs
```
* Apply state

```bash
salt saltmompri state.apply create_envs
```

## API

* ***TODO*** - Add curl commands

## Description of interaction with external systems.

* Used by all versioned formulas

## Logs
* Errors within the state may be written to the master log.
	* **/etc/log/salt/master**
* State output goes to the salt minion log.
	* **/etc/log/salt/minion**

# Common Errors
* A formula is defined in pillar without "version=" or "absent" set.

```
       ----------
                 ID: failure
           Function: test.fail_without_changes
               Name: create_envs must either define a version or absent for each formula
             Result: False
            Comment: Failure!
            Started: 19:32:50.677279
           Duration: 0.601 ms
            Changes:
```

* Pillar identifies a version of a formula that does not exist on this server
*Validate that this version has been deployed*

```
       ----------
                 ID: failure
           Function: test.fail_without_changes
               Name: create_envs /srv/versioned_formulas/example_a_1.0.3/example_a does not exist. Check to see that this version is deployed on this server.
             Result: False
            Comment: Failure!
            Started: 19:44:24.570043
           Duration: 0.575 ms
            Changes:
```

# Deployment
* All deployments will be done from the Gitlab CI/CD pipeline

# Testing

## Kitchen dependencies

* Execute testing setup from
	* specifically you need the salt virtual env and requirements from salt.

## Running kitchen tests from the command line

```bash
virtualenv ./formulaenv
source ./formulaenv/bin/activate
pip install -r requirements.txt
gem install bundle
bundle install
bundle exec kitchen test 2>&1 | tee execute_tests.html
deactivate
rm -rf ./formulaenv
```

## Useful Kitchen commands

***Note if verify succedes then container/vm is destroyed, on failure, the container/vm is left up.***

* Run tests

```bash
kitchen test
```

* Run the salt state on the Kitchen container/vm

```bash
kitchen converge
```

* Just run the verification step
    * Run python test files against an already created container/vm

```bash
kitchen verify
```

* Log into a container/vm

```bash
kitchen login
```

* Additional Kitchen commands
    * [Kitchen CI Docs](https://kitchen.ci/docs/getting-started/getting-help/)

## Unit
* Combined with Integration Testing.
* Tests all defined functionality

## Integration
* Performs Integration testing using Kitchen Salt Framework - [Testing Salt Formulas](https://salt-formulas.readthedocs.io/en/latest/develop/testing-formulas.html)
* Also uses [testinfra](https://testinfra.readthedocs.io/en/latest/) for state verification.

All of these tests setup clean docker images on the gitlab-runner. They install salt, and apply the state, then check the state of the server to validate that the state was applied correctly.

## Performance
* ***Not currently Performed***

## QA guidance
* ***N/A***

# External Libraries
* TestInfra
	* Apache 2.0
* Kitchen Salt
	* MIT
* Docker
	* Apache 2.0

# Reference Pages
* [Kitchen CI Docs](https://kitchen.ci/docs/getting-started/getting-help/)
