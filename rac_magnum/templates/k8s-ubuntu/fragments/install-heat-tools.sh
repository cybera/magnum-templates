#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Enable security updates
/usr/local/bin/enableAutoUpdate

# Install python requests
apt-get update -qq

apt-get install -y python3-pip
pip3 install os-collect-config os-apply-config os-refresh-config dib-utils heat-cfntools
cfn-create-aws-symlinks
