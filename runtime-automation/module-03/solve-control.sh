#!/bin/sh
echo "Solved module called module-02" >> /tmp/progress.log

## solve-inventory

## run inventory tasks from setup plabyook
su --login rhel -c '/home/rhel/.local/bin/ansible-navigator run /tmp/controller-101-setup.yml --tags solve-inventory-all'
