#!/bin/bash

. /etc/default/heat-params

mkdir -p /etc/kubernetes/
KUBE_OS_CLOUD_CONFIG=/etc/kubernetes/cloud-config

# Generate a the configuration for Kubernetes services
# to talk to OpenStack Neutron and Cinder
cat > $KUBE_OS_CLOUD_CONFIG <<EOF
[Global]
auth-url=$AUTH_URL
user-id=$TRUSTEE_USER_ID
password=$TRUSTEE_PASSWORD
trust-id=$TRUST_ID
domain-id=$TRUSTEE_DOMAIN_ID
[BlockStorage]
bs-version=v3
EOF
