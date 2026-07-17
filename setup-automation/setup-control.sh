#!/bin/bash

# Register with Satellite for RHEL repos (clean stale certs from base image)
subscription-manager clean
curl -k -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt
update-ca-trust
rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm
subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY}

systemctl stop systemd-tmpfiles-setup.service
systemctl disable systemd-tmpfiles-setup.service

echo "192.168.1.10 control.lab control controller" >> /etc/hosts

echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
chmod 440 /etc/sudoers.d/rhel_sudoers

# SSH keys for rhel user
RHEL_PRIVATE_KEY="/home/rhel/.ssh/id_rsa"
if [ -f "$RHEL_PRIVATE_KEY" ]; then
    echo "SSH key already exists for rhel user"
else
    echo "Creating SSH key for rhel user..."
    sudo -u rhel mkdir -p /home/rhel/.ssh
    sudo -u rhel chmod 700 /home/rhel/.ssh
    sudo -u rhel ssh-keygen -t rsa -b 4096 -m PEM -C "rhel@$(hostname)" -f /home/rhel/.ssh/id_rsa -N "" -q
    sudo -u rhel chmod 600 /home/rhel/.ssh/id_rsa*
fi

# Ansible directories and config for rhel user
mkdir -p /home/rhel/ansible /home/rhel/ansible-files

cat > /home/rhel/.ansible.cfg << 'EOF'
[defaults]
inventory = /home/rhel/ansible-files/hosts
host_key_checking = False
EOF

# git setup
su - rhel -c 'git config --global user.email "rhel@example.com"'
su - rhel -c 'git config --global user.name "Red Hat"'

# ansible-navigator settings
cat > /home/rhel/ansible-navigator.yml << 'EOF'
---
ansible-navigator:
  ansible:
    inventory:
      entries:
      - /home/rhel/ansible-files/hosts
  execution-environment:
    container-engine: podman
    container-options:
      - "--net=host"
    enabled: true
    image: registry.redhat.io/ansible-automation-platform-27/ee-supported-rhel9
    pull:
      policy: missing
    environment-variables:
      pass:
        - CONTROLLER_USERNAME
        - CONTROLLER_PASSWORD
        - CONTROLLER_VERIFY_SSL
      set:
        CONTROLLER_HOST: localhost
  logging:
    level: debug
  mode: stdout
  playbook-artifact:
    save-as: /home/rhel/{playbook_name}-artifact-{time_stamp}.json
EOF

cp /home/rhel/ansible-navigator.yml /home/rhel/.ansible-navigator.yml
cp /home/rhel/ansible-navigator.yml /home/rhel/ansible-files/ansible-navigator.yml

# Inventory hosts file
cat > /home/rhel/ansible-files/hosts << 'EOF'
[web]
node1
node2

[database]
node3

[controller]
control
EOF

chown -R rhel:rhel /home/rhel/ansible /home/rhel/ansible-files
chmod 777 /home/rhel/ansible

# Controller as Code (CaC) setup
# Create venv with ansible-core 2.16.x (matches ee-supported-rhel9)
# CaC files are copied to /tmp/controller-as-code/ by setup-automation/main.yml
dnf install -y --disablerepo='*rhui*' python3-pip python3.11 python3.11-pip
python3.11 -m venv /tmp/cac-venv
/tmp/cac-venv/bin/pip install --quiet --upgrade pip
/tmp/cac-venv/bin/pip install --quiet "ansible-core~=2.16.0"
/tmp/cac-venv/bin/ansible-galaxy collection install infra.aap_configuration:==4.7.0

# Pre-create credentials so they exist before module-05
/tmp/cac-venv/bin/ansible-playbook /tmp/controller-as-code/configure_controller_credentials.yml
