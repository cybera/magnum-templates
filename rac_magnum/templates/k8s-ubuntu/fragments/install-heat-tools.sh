#!/bin/bash

# Enable security updates
/usr/local/bin/enableAutoUpdate

# Install python requests
apt-get update -qq

apt-get install -y python-pip
pip install os-collect-config os-apply-config os-refresh-config dib-utils heat-cfntools
cfn-create-aws-symlinks
