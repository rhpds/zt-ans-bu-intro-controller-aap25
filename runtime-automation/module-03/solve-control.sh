#!/bin/sh
echo "Solved module called module-02" >> /tmp/progress.log

set -e

INVENTORY="Lab-Inventory"
HOSTS=(node1 node2)
GROUP="web"

#Ansible settings
export ANSIBLE_STDOUT_CALLBACK="community.general.yaml"

## Check all

CMDALL="su --login rhel -c '/home/rhel/.local/bin/ansible-navigator run /tmp/controller-101-setup.yml --tags check-inventory-all'"


## Check $INVENTORY exists.

CMDINV="su --login rhel -c '/home/rhel/.local/bin/ansible-navigator run /tmp/controller-101-setup.yml --tags check-inventory --mode stdout'"

if ! eval "$CMDINV"; then
  echo "FAIL: ${INVENTORY} inventory not found. Remember it's case-sensitive! Please try again."
  exit 1
fi


## Check hosts are in $INVENTORY

CMDHOSTS="su --login rhel -c '/home/rhel/.local/bin/ansible-navigator run /tmp/controller-101-setup.yml --tags check-inv-hosts --mode stdout'"

for host in "${HOSTS[@]}"; do
  if ! eval "$CMDHOSTS"; then
  echo "FAIL: node1 or node2 are missing from ${INVENTORY} or there is a duplicate host in another inventory. If so, please remove the duplicate ${host} host and check again. Remember it's case-sensititve!"
  exit 1
  fi
done

## Check $GROUP is in $INVENTORY

CMDGROUP="su --login rhel -c '/home/rhel/.local/bin/ansible-navigator run /tmp/controller-101-setup.yml --tags check-inv-group --mode stdout'"

if ! eval "$CMDGROUP"; then
    echo "FAIL: ${GROUP} group is missing, node1 and node2 are not in the group, or there is a duplicate ${GROUP} group in another inventory. If so, please remove the duplicate ${GROUP} group and check again. Remember it's case-sensititve!"
    echo "Remember it's case-sensititve! Please try again."
    exit 1
fi
