# -*- coding: utf-8 -*-
# vim: ft=sls

/tmp/kitchen/etc/salt/grains:
  file.managed:
    - contents: |
        deploy_location: default

symlink_etc_salt_grains:
  file.symlink:
    - name: /etc/salt/grains
    - target: /tmp/kitchen/etc/salt/grains
    - user: root
    - group: root

