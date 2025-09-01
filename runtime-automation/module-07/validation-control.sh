#!/bin/sh
echo "Validated module called module-02" >> /tmp/progress.log

set -e


INVENTORY="Lab-Inventory"
PROJECT="Apache playbooks"
PROJECT2="Additional playbooks"
TEMPLATE="Install Apache"
TEMPLATE2="Set motd"
TEMPLATE3="Extended services"
WORKFLOW="Your first workflow"
HOSTS=(node1 node2)
GROUP="web"

#Ansible settings
export ANSIBLE_STDOUT_CALLBACK="community.general.yaml"


## Run --tags check-project 2
CMD="su --login rhel -c '/home/rhel/.local/bin/ansible-navigator run /tmp/controller-101-setup.yml --tags check-project2 --mode stdout'"

# Check $PROJECT2 exists.
if ! eval "$CMD"; then
  echo "FAIL: ${PROJECT2} project not found or something else is wrong. Remember it's case-sensitive! Please try again."
  exit 1
fi
