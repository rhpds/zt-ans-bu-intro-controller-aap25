#!/bin/bash

systemctl stop systemd-tmpfiles-setup.service
systemctl disable systemd-tmpfiles-setup.service


# Install collection(s)
# ansible-galaxy collection install community.general

nmcli connection add type ethernet con-name enp2s0 ifname enp2s0 ipv4.addresses 192.168.1.10/24 ipv4.method manual connection.autoconnect yes
nmcli connection up enp2s0
echo "192.168.1.10 control.lab control controller" >> /etc/hosts

su - rhel -c 'pip install ansible-navigator'

echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
chmod 440 /etc/sudoers.d/rhel_sudoers
echo "Checking SSH keys for rhel user..."

RHEL_SSH_DIR="/home/rhel/.ssh"
RHEL_PRIVATE_KEY="$RHEL_SSH_DIR/id_rsa"
RHEL_PUBLIC_KEY="$RHEL_SSH_DIR/id_rsa.pub"

if [ -f "$RHEL_PRIVATE_KEY" ]; then
    echo "SSH key already exists for rhel user: $RHEL_PRIVATE_KEY"
else
    echo "Creating SSH key for rhel user..."
    sudo -u rhel mkdir -p /home/rhel/.ssh
    sudo -u rhel chmod 700 /home/rhel/.ssh
    sudo -u rhel ssh-keygen -t rsa -b 4096 -C "rhel@$(hostname)" -f /home/rhel/.ssh/id_rsa -N "" -q
    sudo -u rhel chmod 600 /home/rhel/.ssh/id_rsa*
    
    if [ -f "$RHEL_PRIVATE_KEY" ]; then
        echo "SSH key created successfully for rhel user"
    else
        echo "Error: Failed to create SSH key for rhel user"
    fi
fi

# # ## setup rhel user
touch /etc/sudoers.d/rhel_sudoers
echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
# # cp -a /root/.ssh/* /home/$USER/.ssh/.
# # chown -R rhel:rhel /home/$USER/.ssh
# export CONTROLLER_USERNAME=admin
# export CONTROLLER_PASSWORD=ansible123!
# export CONTROLLER_VERIFY_SSL=false

# ## ansible home
mkdir /home/$USER/ansible
## ansible-files dir
mkdir /home/$USER/ansible-files

# ## ansible.cfg
echo "[defaults]" > /home/$USER/.ansible.cfg
echo "inventory = /home/$USER/ansible-files/hosts" >> /home/$USER/.ansible.cfg
echo "host_key_checking = False" >> /home/$USER/.ansible.cfg

# ## chown and chmod all files in rhel user home
# chown -R rhel:rhel /home/$USER/ansible
# chmod 777 /home/$USER/ansible
# #touch /home/rhel/ansible-files/hosts
# chown -R rhel:rhel /home/$USER/ansible-files

# ## git setup
git config --global user.email "rhel@example.com"
git config --global user.name "Red Hat"
su - $USER -c 'git config --global user.email "rhel@example.com"'
su - $USER -c 'git config --global user.name "Red Hat"'


# ## set ansible-navigator default settings
# ## for the EE to work we need to pass env variables
# ## TODO: controller_host doesnt resolve with control and 127.0.0.1
# ## is interpreted within the EE
su - $USER -c 'cat >/home/$USER/ansible-navigator.yml <<EOL
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
    image: registry.redhat.io/ansible-automation-platform-25/ee-supported-rhel9
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

# EOL
# cat /home/$USER/ansible-navigator.yml'

# ## copy navigator settings
su - $USER -c 'cp /home/$USER/ansible-navigator.yml /home/$USER/.ansible-navigator.yml'
su - $USER -c 'cp /home/$USER/ansible-navigator.yml /home/$USER/ansible-files/ansible-navigator.yml'


git clone https://github.com/ansible-tmm/controller-101.git /tmp/controller-101-2024


# ## set inventory hosts for commandline ansible
su - $USER -c 'cat >/home/$USER/ansible-files/hosts <<EOL
[web]
node1
node2

[database]
node3

[controller]
control

EOL
cat /home/$USER/ansible-files/hosts'
## end inventory hosts

# ## chown and chmod all files in rhel user home
chown -R rhel:rhel /home/rhel/ansible
chmod 777 /home/rhel/ansible
#touch /home/rhel/ansible-files/hosts
chown -R rhel:rhel /home/rhel/ansible-files

## install ansible-navigator
dnf install -y python3-pip 
su - $USER -c 'python3 -m pip install ansible-navigator --user'
echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/$USER/.profile
echo 'export PATH=$HOME/.local/bin:$PATH' >> /etc/profile

# # # creates a playbook to setup environment

tee /tmp/setup.yml << EOL
---
### Automation Controller setup 
###
- name: Setup Controller 
  hosts: localhost
  connection: local
  collections:
    - ansible.controller
  vars:
    GUID: "{{ lookup('env', 'GUID') | default('GUID_NOT_FOUND', true) }}"
    DOMAIN: "{{ lookup('env', 'DOMAIN') | default('DOMAIN_NOT_FOUND', true) }}"
    inventory_name: Lab-Inventory
    credentials_name: lab-credentials
    controller_host: "https://localhost"
    controller_username: admin
    controller_password: ansible123!
    validate_certs: false
    
  tasks:

    - name: Create an inventory in automation controller
      ansible.controller.inventory:
        name: Lab-Inventory
        organization: Default
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      tags:
        - solve-inventory 
        - solve-inventory-all
        - solve-workflow
        - solve-all

    - name: Add node1 and node2 to Lab-Inventory
      ansible.controller.host:
        name: "{{ item }}"
        inventory: Lab-Inventory
        state: present
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      loop:
        - node1
        - node2
      tags:
        - solve-inventory-hosts
        - solve-inventory-all
        - solve-workflow
        - solve-all

    - name: Create web group and add node1 and node2 
      ansible.controller.group:
        name: web
        inventory: Lab-Inventory
        hosts:
          - node1
          - node2    
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      tags:
        - solve-inventory-group
        - solve-inventory-all
        - solve-workflow
        - solve-all

    - name: Create machine Credentials for the lab
      ansible.controller.credential:
        name: lab-credentials
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
        credential_type: Machine
        organization: Default
        inputs:
          username: rhel 
          ssh_key_data: "{{ lookup('file', '/home/rhel/.ssh/id_rsa' ) }}"
      tags:
        - solve-credentials
        - solve-workflow
        - solve-all

    - name: Create your first apache playbooks Project from git
      ansible.controller.project:
        name: "Apache playbooks"
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
        organization: Default
        state: present
        scm_type: git
        scm_url: https://github.com/ansible-tmm/instruqt-wyfp.git
      tags:
        - solve-project
        - solve-workflow
        - solve-all

    - name: Launch apache playbooks project sync 
      ansible.controller.project_update:
        project: "Apache playbooks"
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
        wait: true
      tags:
        - solve-project
        - solve-workflow
        - solve-all
  
    - name: Create install apache Job Template
      ansible.controller.job_template:
        name: "Install Apache"
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
        organization: Default
        state: present
        inventory: Lab-Inventory
        become_enabled: true
        playbook: apache.yml
        project: Apache playbooks 
        credential: lab-credentials 
      tags:
        - solve-job_template 
        - solve-workflow
        - solve-all

    - name: Launch the Apache Job Template
      ansible.controller.job_launch:
        job_template: "Install Apache"
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      register: job_apache
      tags:
        - solve-job_template
        - solve-jt_apache
        - solve-workflow
        - solve-all

    - name: Create a second Project from git, additional playbooks
      ansible.controller.project:
        name: "Additional playbooks"
        organization: Default
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
        state: present
        scm_type: git
        scm_url: https://github.com/ansible-tmm/instruqt-wyfp-additional.git
      tags:
        - solve-project2
        - solve-workflow
        - solve-all

    - name: Launch additional playbooks project sync 
      ansible.controller.project_update:
        project: "Additional playbooks"
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
        wait: true
      tags:
        - solve-project2
        - solve-workflow
        - solve-all

    - name: Create set motd Job Template
      ansible.controller.job_template:
        name: "Set motd"
        organization: Default
        state: present
        inventory: Lab-Inventory
        become_enabled: true
        playbook: motd_facts.yml
        project: "Additional playbooks" 
        credential: lab-credentials 
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      tags:
        - solve-job_template3
        - solve-workflow
        - solve-all

    - name: Launch the set motd Job Template
      ansible.controller.job_launch:
        job_template: "Set motd"
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      register: job_motd
      tags:
        - solve-job_template3
        - solve-jt_motd
        - solve-workflow
        - solve-all

    - name: Add node3 to Lab-Inventory
      ansible.controller.host:
        name: node3
        inventory: Lab-Inventory
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
        state: present
      tags:
        - solve-pre-workflow
        - solve-node3
        - solve-job_template2
        - solve-workflow
        - solve-all

    - name: Create database group and add node3 
      ansible.controller.group:
        name: database
        inventory: Lab-Inventory
        hosts:
          - node3    
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      tags:
        - solve-pre-workflow
        - solve-database
        - solve-job_template2
        - solve-workflow
        - solve-all

    - name: Create Extended services Job Template
      ansible.controller.job_template:
        name: "Extended services"
        organization: Default
        state: present
        inventory: Lab-Inventory
        become_enabled: true
        playbook: extended_services.yml
        project: "Additional playbooks" 
        credential: lab-credentials 
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      tags:     
        - solve-job_template2
        - solve-workflow   
        - solve-all

    - name: Launch the Extended services Job Template
      ansible.controller.job_launch:
        job_template: "Extended services"
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      register: job_extended
      tags:
        - solve-job_template2
        - solve-jt_extended
        - solve-workflow
        - solve-all

    - name: Create a Job Template with Survey
      ansible.controller.job_template: 
        name: "Install Apache with Survey"
        organization: "Default"
        state: "present"
        inventory: "Lab-Inventory"
        become_enabled: true
        playbook: "apache_template.yml"
        project: "Apache playbooks"
        credential: lab-credentials
        survey_enabled: true
        survey_spec: "{{ lookup('file', 'controller-101-2024/playbooks-apache/files/apache_survey.json') }}"
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      tags:
          - solve-jt_survey
          - solve-all

    - name: Launch the Apache Job Template with Survey
      ansible.controller.job_launch:
        job_template: "Install Apache with Survey"
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      register: job_apache_survey
      tags:
        - solve-jt_survey_launch
        - solve-all

    - name: Create a Workflow Template
      ansible.controller.workflow_job_template:
        name: Your first workflow
        description: Create a Workflow from previous Job Templates
        organization: Default
        inventory: Lab-Inventory
        workflow_nodes:
          - identifier: apache101
            unified_job_template:
              organization:
                name: Default
              name: "Install Apache"
              type: job_template
            credentials: []
            related:
              success_nodes:
                - identifier: extended201
                - identifier: motd201
              failure_nodes: []
              always_nodes: []
              credentials: []
          - identifier: extended201
            unified_job_template:
              organization:
                name: Default
              name: "Extended services"
              type: job_template
            credentials: []
            related:
              success_nodes: []
              failure_nodes: []
              always_nodes: []
              credentials: []
          - identifier: motd201
            unified_job_template:
              organization:
                name: Default
              name: "Set motd"
              type: job_template
            credentials: []
            related:
              success_nodes: []
              failure_nodes: []
              always_nodes: []
              credentials: []    
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      tags:
        - setup-workflow
        - solve-workflow

#########################################
####        CHECK MODE
#########################################

    - name: Check inventory 
      ansible.controller.inventory:
        name: Lab-Inventory
        organization: Default
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
        kind: ""
      check_mode: true
      register: check_inv
      failed_when: check_inv.changed
      tags:
        - check-inventory
        - check-all

    - name: Check node1 and node2 in Lab-Inventory
      ansible.controller.host:
        name: "{{ item }}"
        inventory: Lab-Inventory
        state: present
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      loop:
        - node1
        - node2
      check_mode: true
      register: check_inv_hosts
      failed_when: check_inv_hosts.changed
      tags:
        - check-hosts
        - check-inv-hosts
        - check-all

    - name: Check web group and add hosts 
      ansible.controller.group:
        name: web
        inventory: Lab-Inventory
        hosts:
          - node1
          - node2   
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      check_mode: true
      register: check_inv_group
      failed_when: check_inv_group.changed
      tags:
        - check-group 
        - check-inv-group
        - check-all

    - name: Check your first Project from git
      ansible.controller.project:
        name: "Apache playbooks"
        organization: Default
        state: present
        scm_type: git
        scm_url: https://github.com/ansible-tmm/instruqt-wyfp.git
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      check_mode: true
      register: check_proj
      failed_when: check_proj.changed
      tags:
        - check-project
        - check-all

    - name: Check Apache Job Template
      ansible.controller.job_template:
        name: "Install Apache"
        organization: Default
        state: present
        inventory: Lab-Inventory
        become_enabled: true
        playbook: apache.yml
        project: Apache playbooks 
        credential: lab-credentials 
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      check_mode: true
      register: check_jt_apache
      failed_when: check_jt_apache.changed
      tags:
        - check-job_template 
        - check-all

    - name: Check an additional Project from git
      ansible.controller.project:
        name: "Additional playbooks"
        organization: Default
        state: present
        scm_type: git
        scm_url: https://github.com/ansible-tmm/instruqt-wyfp-additional.git
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      check_mode: true
      register: check_proj2
      failed_when: check_proj2.changed
      tags:
        - check-project2
        - check-all

    - name: Check a motd Job Template
      ansible.controller.job_template:
        name: "Set motd"
        organization: Default
        state: present
        inventory: Lab-Inventory
        become_enabled: true
        playbook: motd_facts.yml
        project: "Additional playbooks" 
        credential: lab-credentials 
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      check_mode: true
      register: check_jt_motd
      failed_when: check_jt_motd.changed
      tags:
        - check-job_template3  
        - check-all

    - name: Check extended services Job Template
      ansible.controller.job_template:
        name: "Extended services"
        organization: Default
        state: present
        inventory: Lab-Inventory
        become_enabled: true
        playbook: extended_services.yml
        project: "Additional playbooks" 
        credential: lab-credentials 
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      check_mode: true
      register: check_jt_ext
      failed_when: check_jt_ext.changed
      tags:
        - check-job_template2         
        - check-all

    - name: Check node3 to Lab-Inventory
      ansible.controller.host:
        name: node3
        inventory: Lab-Inventory
        state: present
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      check_mode: true
      register: check_inv_host3
      failed_when: check_inv_host3.changed
      tags:
        - check-pre-workflow
        - check-node3
        - check-all

    - name: Check database group and add host
      ansible.controller.group:
        name: database
        inventory: Lab-Inventory
        hosts:
          - node3    
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      check_mode: true
      register: check_inv_grp_db
      failed_when: check_inv_grp_db.changed
      tags:
        - check-pre-workflow
        - check-database
        - check-all

    - name: Check a Workflow Template
      ansible.controller.workflow_job_template:
        name: "Your first workflow"
        description: Create a Workflow from previous Job Templates
        organization: Default
        inventory: Lab-Inventory
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
        workflow_nodes:
          - identifier: apache101
            unified_job_template:
              organization:
                name: Default
              name: "Install Apache"
              type: job_template
            credentials: []
            related:
              success_nodes:
                - identifier: extended201
                - identifier: motd201
              failure_nodes: []
              always_nodes: []
              credentials: []
          - identifier: extended201
            unified_job_template:
              organization:
                name: Default
              name: "Extended services"
              type: job_template
            credentials: []
            related:
              success_nodes: []
              failure_nodes: []
              always_nodes: []
              credentials: []
          - identifier: motd201
            unified_job_template:
              organization:
                name: Default
              name: "Set motd"
              type: job_template
            credentials: []
            related:
              success_nodes: []
              failure_nodes: []
              always_nodes: []
              credentials: []   
      check_mode: true
      register: check_workflow
      failed_when: check_workflow.changed
      tags:
        - check-workflow-only
        - check-workflow  
        - check-all

    - name: Check Apache with Survey
      ansible.controller.job_template: 
        name: "Install Apache with Survey"
        organization: "Default"
        state: "present"
        inventory: "Lab-Inventory"
        become_enabled: true
        playbook: "apache_template.yml"
        project: "Apache playbooks"
        credential: lab-credentials
        survey_enabled: true
        survey_spec: "{{ lookup('file', 'controller-101-2024/playbooks-apache/files/apache_survey.json') }}"
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      check_mode: true
      register: check_survey
      failed_when: check_survey.changed
      tags:
          - check-jt_survey
          - check-all
      
    - name: Print jt_survey
      ansible.builtin.debug:
        var: check_survey
        verbosity: 2
      tags:
        - check-jt_survey

#########################################
## execution checks // apache service, package, html
#########################################

    - name: Check that apache is working in node1
      ansible.builtin.uri:
        url: http://node1
        return_content: true
      register: apache_node1
      until: apache_node1.status == 200
      retries: 720 # 720 * 5 seconds = 1hour (60*60/5)
      delay: 5 # Every 5 seconds
      failed_when: "'webserver' not in apache_node1.content"
      tags:
        - check-apache-uri
        - check-apache

    - name: Check that apache is working in node2
      ansible.builtin.uri:
        url: http://node2
        return_content: true
      register: apache_node2
      until: apache_node2.status == 200
      retries: 720 # 720 * 5 seconds = 1hour (60*60/5)
      delay: 5 # Every 5 seconds
      failed_when: "'webserver' not in apache_node2.content"
      tags:
        - check-apache-uri
        - check-apache

    - name: Check httpd service is started
      ansible.builtin.service:
        name: httpd
        state: started
        enabled: true
      delegate_to: "{{ item }}"
      loop:
        - node1
        - node2
      check_mode: true
      tags:
        - check-apache-service
        - check-apache

    - name: Check the Apache Job Template launches successfully
      ansible.controller.job_launch:
        job_template: "Install Apache"
        wait: true
        timeout: 120
        controller_host: "https://localhost"
        controller_username: admin
        controller_password: ansible123!
        validate_certs: false
      ignore_errors: true
      register: job_apache_check
      tags:
        - check-jt_apache

    - name: Verify if the apache job was successful
      ansible.builtin.assert:
        that: job_apache_check.status == 'successful'
        success_msg: "The job was successful."
        fail_msg: "The job failed."
      tags:
        - check-jt_apache

EOL

# ANSIBLE_COLLECTIONS_PATH=/tmp/ansible-automation-platform-containerized-setup-bundle-2.5-9-x86_64/collections/:/root/.ansible/collections/ansible_collections/ ansible-playbook -i /tmp/inventory /tmp/setup.yml
