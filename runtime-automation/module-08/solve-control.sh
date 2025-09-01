#!/bin/sh
echo "Solved module called module-02" >> /tmp/progress.log

## solve-job_template2

## run tasks from setup plabyook / add node3 to inventory
su --login rhel -c '/home/rhel/.local/bin/ansible-navigator run /tmp/controller-101-setup.yml --tags solve-node3'

## run tasks from setup plabyook / Create Extended services Job Template
su --login rhel -c '/home/rhel/.local/bin/ansible-navigator run /tmp/controller-101-setup.yml --tags solve-job_template2'

## run tasks from setup plabyook /Create set motd Job Template
su --login rhel -c '/home/rhel/.local/bin/ansible-navigator run /tmp/controller-101-setup.yml --tags solve-job_template3'
