#!/bin/bash
curl -k  -L https://${SATELLITE_URL}/pub/katello-server-ca.crt -o /etc/pki/ca-trust/source/anchors/${SATELLITE_URL}.ca.crt
update-ca-trust
rpm -Uhv https://${SATELLITE_URL}/pub/katello-ca-consumer-latest.noarch.rpm

subscription-manager register --org=${SATELLITE_ORG} --activationkey=${SATELLITE_ACTIVATIONKEY}

touch /etc/sudoers.d/rhel_sudoers
echo "%rhel ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/rhel_sudoers
cp -a /root/.ssh/* /home/rhel/.ssh/.
chown -R rhel:rhel /home/rhel/.ssh

## ^ from getting started controller

## COMMENT CENTOS 
# dnf config-manager --disable rhui*,google*

# sudo bash -c 'cat >/etc/yum.repos.d/centos8-baseos.repo <<EOL
# [centos8-baseos]
# name=CentOS 8 Stream BaseOS
# baseurl=http://mirror.centos.org/centos/8-stream/BaseOS/x86_64/os
# enabled=1
# gpgcheck=0

# EOL
# cat /etc/yum.repos.d/centos8-baseos.repo'

# sudo bash -c 'cat >/etc/yum.repos.d/centos8-appstream.repo <<EOL
# [centos8-appstream]
# name=CentOS 8 Stream AppStream
# baseurl=http://mirror.centos.org/centos/8-stream/AppStream/x86_64/os/
# enabled=1
# gpgcheck=0

# EOL
# cat /etc/yum.repos.d/centos8-appstream.repo'
## END COMMENT CENTOS 

## clean repo metadata and refresh
dnf config-manager --disable google*
dnf clean all
dnf config-manager --enable rhui-rhel-9-for-x86_64-baseos-rhui-rpms
dnf config-manager --enable rhui-rhel-9-for-x86_64-appstream-rhui-rpms
dnf makecache

#Install a package to build metadata of the repo and not need to wait during labs
#dnf install -y cups-filesystem

# stop web server
systemctl stop nginx

# make Dan Walsh weep: https://stopdisablingselinux.com/
setenforce 0

