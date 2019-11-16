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
import yaml

def test_saltenv_conf(File):
    '''

    Test test_directories
    1) default formula and pillar symlinks
    2) new environment creation

    '''

    conf=File('/etc/salt/minion.d/saltenv.conf')
    assert conf.exists

    environments_file=yaml.safe_load(conf.content_string)
    assert environments_file['pillarenv'] == 'test_env'
    assert environments_file['saltenv'] == 'test_env'

def test_minion_restart(File):
    '''

    Test test_directories
    1) validate that formula runs on a docker container

    '''

    log_file=File('/var/log/salt/minion')
    assert log_file.exists

    assert log_file.contains('SIGTERM')

def test_minion_service(Service):
    '''

    Test salt-master service
    1) salt-master restart on change to environment.conf

    '''

    salt_master_service=Service('salt-minion')

    assert salt_master_service.is_running
    assert salt_master_service.is_enabled

