# -*- coding: utf-8 -*-
'''

Test
We don't know anything about the setup of this pillar
Validate the basics:
1) environments.conf is a valid yaml file.
2) salt-master is running
Written by Brad Chapin (bradley.chapin@centurylink.com)

'''

from __future__ import absolute_import
# import testinfra
import yaml

def test_versioned_formulas_sync(File):
    '''

    Validate the synce pulls down assigned formulas

    '''

    ###  Common Formulas

    # Common Formulas - validate pull down versioned directory
    formula_dir=File('/srv/versioned_formulas/example_a_1.0.0')
    assert formula_dir.is_directory

    # Common Formulas - validate pull down formula directory
    formula=File('/srv/versioned_formulas/example_a_1.0.0/example_a')
    assert formula.is_directory

    # Common Formulas - validate pull down contents of directory
    formula=File('/srv/versioned_formulas/example_a_1.0.0/example_a/init.sls')
    assert formula.is_file

    # Common Formulas - validate pull down pillar
    formula=File('/srv/versioned_formulas/example_a_1.0.0/example_a.sls')
    assert formula.is_file

    ### Role Formulas

    # Role Formulas - validate pull down versioned directory
    formula_dir=File('/srv/versioned_formulas/example_b_2.0.1')
    assert formula_dir.is_directory

    # Role Formulas - validate pull down formula directory
    formula=File('/srv/versioned_formulas/example_b_2.0.1/example_b')
    assert formula.is_directory

    # Role Formulas - validate pull down contents of directory
    formula=File('/srv/versioned_formulas/example_b_2.0.1/example_b/init.sls')
    assert formula.is_file

    # Role Formulas - validate pull down multi pillar
    formula=File('/srv/versioned_formulas/example_b_2.0.1/test_env3.sls')
    assert formula.is_file

    # Common Formulas - validate pull down second formula different versioned directory
    formula_dir=File('/srv/versioned_formulas/example_b_1.0.0')
    assert formula_dir.is_directory

    # Common Formulas - validate pull down second formula correct sls
    formula=File('/srv/versioned_formulas/example_b_1.0.0/test_env2.sls')
    assert formula.is_file

    # validate we do not pull down formula directories not destined for this server
    formula=File('/srv/versioned_formulas/example_b_2.0.0')
    assert not formula.is_directory

def test_environment_conf(File):
    '''

    Test test_directories
    1) We don't know anything about the setup of this pillar
       So just testing for valid yaml file
    2) new environment creation

    '''

    conf=File('/etc/salt/master.d/environments.conf')
    assert conf.exists

    try:
        environments_file=yaml.safe_load(conf.content_string)
    except yaml.YAMLError, exc:
        assert True


def test_service(Service):
    '''

    Test salt-master service
    1) salt-master restart on change to environment.conf

    '''

    salt_master_service=Service('salt-master')

    assert salt_master_service.is_running
    assert salt_master_service.is_enabled

def test_absent(File):
    '''

    Test test_absent
    Validate unconfigured formulas are removed from versioned_formulas directory
    1) directories removed
    2) files are not revmoved

    '''
    formula=File('/srv/versioned_formulas/should_be_removed')
    assert not formula.exists

    formula=File('/srv/versioned_formulas/should_exist')
    assert formula.exists

