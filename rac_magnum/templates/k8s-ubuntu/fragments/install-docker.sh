#!/bin/bash

DOCKER_VERSION=18.06

export DEBIAN_FRONTEND=noninteractive

# Enable security updates
/usr/local/bin/enableAutoUpdate
apt-get update -qq

# Fix swap
swapdisk=$(lsblk -fs | grep swap | awk '{print $1}')
swaplabel -L swap0 /dev/$swapdisk
sed -i "/sdb/d" /etc/fstab
sed -i "/sdc/d" /etc/fstab
swapoff -a

# Install Docker
curl -fsSL get.docker.com -o /tmp/get-docker.sh
VERSION=$DOCKER_VERSION bash /tmp/get-docker.sh > /var/log/install-docker.log 2>&1
rm /tmp/get-docker.sh
usermod -aG docker ubuntu
