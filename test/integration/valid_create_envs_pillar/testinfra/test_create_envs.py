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
