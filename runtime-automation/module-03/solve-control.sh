#!/bin/sh
echo "Solved module called module-02" >> /tmp/progress.log

## solve-inventory

## run inventory tasks from setup plabyook
#su --login rhel -c '/home/rhel/.local/bin/ansible-navigator run /tmp/controller-101-setup.yml --tags solve-inventory-all'


su --login rhel -c '/home/rhel/.local/bin/ansible-navigator run ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/setup.yml --tags solve-inventory-all
