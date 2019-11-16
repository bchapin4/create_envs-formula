# -*- coding: utf-8 -*-
'''

Test
1) validate that configs match the overridden pillar settings
2) validate that environments.conf setup properly
Written by Brad Chapin (bradley.chapin@centurylink.com)

'''

from __future__ import absolute_import
import yaml
import time

def test_examples(File):
    '''

    Test test_directories
    1) default formula and pillar symlinks
    2) new environment creation

    '''

    # default formula got created
    formula_dir=File('/srv/formulas/test_env')
    assert formula_dir.is_directory
    assert formula_dir.user=='cdnsalt'
    assert formula_dir.group=='cdnsalt'

    # default formula got created
    formula_dir=File('/srv/formulas/test_env2')
    assert formula_dir.is_directory
    assert formula_dir.user=='cdnsalt'
    assert formula_dir.group=='cdnsalt'

    # validate create_envs gets created for each pillar
    pillar=File('/srv/pillar/test_env/create_envs.sls')
    assert pillar.is_symlink
    assert pillar.linked_to == '/srv/versioned_formulas/create_envs/create_envs.sls'
    assert pillar.user=='cdnsalt'
    assert pillar.group=='cdnsalt'

    # validate create_env_version gets created for each pillar
    pillar=File('/srv/pillar/test_env/create_envs_version.sls')
    assert pillar.is_symlink
    assert pillar.linked_to == '/srv/versioned_formulas/create_envs/create_envs_version.sls'
    assert pillar.user=='cdnsalt'
    assert pillar.group=='cdnsalt'

    # pick up common formula from master (mom)
    # also validate that if no formulas present still gets common formulas
    formula=File('/srv/formulas/test_env/example_a')
    assert formula.is_symlink
    assert formula.linked_to == '/srv/versioned_formulas/example_a_1.0.0/example_a'
    assert formula.user=='cdnsalt'
    assert formula.group=='cdnsalt'

    # pick up common pillar from master (mom)
    # validate that default sls used when <env>.sls is not present
    pillar=File('/srv/pillar/test_env/example_a.sls')
    assert pillar.is_symlink
    assert pillar.linked_to == '/srv/versioned_formulas/example_a_1.0.0/example_a.sls'
    assert pillar.user=='cdnsalt'
    assert pillar.group=='cdnsalt'

    # pick up common pillar from master (mom)
    # validate <env>_version.sls picked up from common when present
    pillar=File('/srv/pillar/test_env/example_a_version.sls')
    assert pillar.is_symlink
    assert pillar.linked_to == '/srv/versioned_formulas/example_a_1.0.0/example_a_version.sls'
    assert pillar.user=='cdnsalt'
    assert pillar.group=='cdnsalt'

    # pick up common pillar from master (mom)
    # defined in common_pillars
    # include embeded directories in pillar name
    # validate that default sls used when <env>.sls is not present
    pillar=File('/srv/pillar/test_env/example_a_groups/admins.sls')
    assert pillar.is_symlink
    assert pillar.linked_to == '/srv/versioned_formulas/example_a_1.0.0/groups/admins.sls'
    assert pillar.user=='cdnsalt'
    assert pillar.group=='cdnsalt'

    # pick up common pillar from master (mom)
    # defined in common_pillars
    # include embeded directories in pillar name
    # validate that default sls used when <env>.sls is not present
    pillar=File('/srv/pillar/test_env/example_a_groups/regular_users.sls')
    assert pillar.is_symlink
    assert pillar.linked_to == '/srv/versioned_formulas/example_a_1.0.0/groups/regular_users.sls'
    assert pillar.user=='cdnsalt'
    assert pillar.group=='cdnsalt'

    # pick up common pillar from master (mom)
    # validate that <env>.sls is used when present
    pillar=File('/srv/pillar/test_env/example_b.sls')
    assert pillar.is_symlink
    assert pillar.linked_to == '/srv/versioned_formulas/example_b_2.0.0/test_env.sls'

    # validate formula removed if not defined in create_envs.sls for this environment.
    formula=File('/srv/formulas/test_env3/example_c')
    assert not formula.exists

    # validate pillar removed if not defined in create_envs.sls for this environment.
    pillar=File('/srv/pillar/test_env3/example_c.sls')
    assert not pillar.exists

    # validate additional pillar from role formula
    pillar=File('/srv/pillar/test_env2/example_c_override_pillar.sls')
    assert pillar.is_symlink
    assert pillar.linked_to == '/srv/versioned_formulas/example_c_1.0.0/override_pillar.sls'

    # validate additional pillar from common formula
    pillar=File('/srv/pillar/test_env/example_b_override_pillar_b1.sls')
    assert pillar.is_symlink
    assert pillar.linked_to == '/srv/versioned_formulas/example_b_2.0.0/override_pillar_b1.sls'

    # validate additional pillar from role formula overrides common formula
    pillar=File('/srv/pillar/test_env2/example_b_override_pillar_b2.sls')
    assert pillar.is_symlink
    assert pillar.linked_to == '/srv/versioned_formulas/example_b_2.0.0/override_pillar_b2.sls'

    # validate common version override in formula
    formula=File('/srv/formulas/test_env/example_b')
    assert formula.is_symlink
    assert formula.linked_to == '/srv/versioned_formulas/example_b_2.0.0/example_b'

    # validate common version override in pillar
    pillar=File('/srv/pillar/test_env3/example_b.sls')
    assert pillar.is_symlink
    assert pillar.linked_to == '/srv/versioned_formulas/example_b_2.0.1/test_env3.sls'

def test_absent(File):
    '''

    Test test_absent
    1) symlinks removed

    '''
    formula=File('/srv/formulas/test_env3/example_c')
    assert not formula.exists

    pillar=File('/srv/pillar/test_env3/example_c.sls')
    assert not pillar.exists


def test_environment_conf(File):
    '''

    Test test_directories
    1) default formula and pillar symlinks
    2) new environment creation

    '''

    conf=File('/etc/salt/master.d/environments.conf')
    assert conf.exists

    environments_file=yaml.safe_load(conf.content_string)
    assert environments_file['pillar_roots']['test_env'] == ['/srv/pillar/test_env']
    assert environments_file['file_roots']['test_env'] == ['/srv/salt', '/srv/salt/test_env', '/srv/formulas', '/srv/formulas/test_env']
    assert environments_file['pillar_roots']['base'] == ['/srv/pillar']
    assert environments_file['file_roots']['base'] == ['/srv/salt', '/srv/formulas', '/srv/versioned_formulas']
    assert environments_file['pillar_roots']['mom'] == ['/srv/pillar/mom']
    assert environments_file['file_roots']['mom'] == ['/srv/salt', '/srv/salt/mom', '/srv/formulas', '/srv/formulas/mom', '/srv/versioned_formulas']

def test_master_service(Service):
    '''

    Test salt-master service
    1) salt-master restart on change to environment.conf

    '''

    salt_master_service=Service('salt-master')

    assert salt_master_service.is_running
    assert salt_master_service.is_enabled

def test_master_restart(File):
    '''

    Test test_directories
    1) validate that formula runs on a docker container

    '''

    log_file=File('/var/log/salt/master')
    assert log_file.exists

    for _ in range(3):
        try:
            assert log_file.contains('SIGTERM')
        except AssertionError:
            time.sleep(5)
        else:
            break
    else:
        assert log_file.contains('SIGTERM')

def test_top_files(File):
    '''

    Test test_directories
    1) default formula and pillar symlinks
    2) new environment creation

    '''

    # validate top file exists for test_env role
    conf=File('/srv/pillar/test_env/top.sls')
    assert conf.exists

    # validate correct yaml
    # validate top contains all pillar files.
    # validate creates additional pillars in top
    environments_file=yaml.safe_load(conf.content_string)
    assert environments_file['test_env'] == {'*': ['create_envs', 'create_envs_version', 'example_a_version', 'example_a_groups.regular_users', 'example_a', 'example_a_groups.admins', 'example_b', 'example_b_override_pillar_b1']}

    # validate top file exists for test_env2 role
    conf=File('/srv/pillar/test_env2/top.sls')
    assert conf.exists

    # validate top file override for additional pillars works.
    environments_file=yaml.safe_load(conf.content_string)
    assert environments_file['test_env2'] == {'*': ['create_envs', 'create_envs_version', 'example_a_version', 'example_a_groups.regular_users', 'example_a', 'example_a_groups.admins', 'example_b', 'example_b_override_pillar_b2', 'example_c', 'example_c_override_pillar']}

    # validate top file exists for test_env3 role
    conf=File('/srv/pillar/test_env3/top.sls')
    assert conf.exists

    # validate picks up common formulas
    environments_file=yaml.safe_load(conf.content_string)
    assert environments_file['test_env3'] == {'*': ['create_envs', 'create_envs_version', 'example_a_version', 'example_a_groups.regular_users', 'example_a', 'example_a_groups.admins', 'example_b', 'example_b_override_pillar_b1']}

def test_masters(File):
    '''

    Test test_masters
    1) Validate that if masters is not set to role of server, then environment not created.

    '''

    formula_dir=File('/srv/formulas/test_env4')
    assert not formula_dir.exists

    pillar_dir=File('/srv/pillar/test_env4')
    assert not pillar_dir.exists

def test_saltenv_conf(File):
    '''

    Test test_directories
    1) default formula and pillar symlinks
    2) new environment creation

    '''

    conf=File('/etc/salt/minion.d/saltenv.conf')
    assert conf.exists

    environments_file=yaml.safe_load(conf.content_string)
    assert environments_file['saltenv'] == 'mom'

def test_minion_restart(File):
    '''

    Test test_directories
    1) validate that formula runs on a docker container

    '''

    log_file=File('/var/log/salt/minion')
    assert log_file.exists

    for _ in range(3):
        try:
            assert log_file.contains('SIGTERM')
        except AssertionError:
            time.sleep(5)
        else:
            break
    else:
        assert log_file.contains('SIGTERM')


def test_minion_service(Service):
    '''

    Test salt-minion service
    1) salt-minion restart on change to environment.conf

    '''

    salt_master_service=Service('salt-minion')

    assert salt_master_service.is_running
    assert salt_master_service.is_enabled

def test_not_absent(File):
    '''

    Test test_absent
    Test that the directory is not removed if role is "mom"
    1) directories not removed

    '''

    # This file is not removed from
    formula=File('/srv/versioned_formulas/should_be_removed')
    assert formula.exists
