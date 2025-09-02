#!/bin/sh
echo "Solved module called module-02" >> /tmp/progress.log

## solve-jt_survey


cd /home/rhel/ansible-files

## download json
/usr/bin/curl https://raw.githubusercontent.com/leogallego/instruqt-wyfp/main/files/apache_survey.json -o /home/rhel/ansible-files/apache_survey.json


mkdir /tmp/files
cp /home/rhel/ansible-files/apache_survey.json /tmp/files


## run tasks from setup plabyook
ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/setup.yml --tags solve-jt_survey --mode stdout'
