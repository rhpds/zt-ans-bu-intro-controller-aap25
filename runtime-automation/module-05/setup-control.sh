#!/bin/sh
## run tasks from setup plabyook
su --login rhel -c '/home/rhel/.local/bin/ansible-navigator run /tmp/controller-101-setup.yml --tags solve-credentials'
