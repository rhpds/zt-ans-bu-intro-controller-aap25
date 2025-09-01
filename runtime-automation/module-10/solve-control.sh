#!/bin/sh
echo "Solved module called module-02" >> /tmp/progress.log

## solve-jt_survey


cd /home/rhel/ansible-files

## download json
/usr/bin/curl https://raw.githubusercontent.com/leogallego/instruqt-wyfp/main/files/apache_survey.json -o /home/rhel/ansible-files/apache_survey.json


mkdir /tmp/files
cp /home/rhel/ansible-files/apache_survey.json /tmp/files


## run tasks from setup plabyook
su --login rhel -c '/home/rhel/.local/bin/ansible-navigator run /tmp/controller-101-setup.yml --tags solve-jt_survey --mode stdout'
