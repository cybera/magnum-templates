#!/bin/bash

. /etc/default/heat-params

mkdir -p /etc/kubernetes/
KUBE_OS_CLOUD_CONFIG=/etc/kubernetes/kube_openstack_config

# Generate a the configuration for Kubernetes services
# to talk to OpenStack Neutron and Cinder
cat > $KUBE_OS_CLOUD_CONFIG <<EOF
[Global]
auth-url=$AUTH_URL
user-id=$TRUSTEE_USER_ID
password=$TRUSTEE_PASSWORD
trust-id=$TRUST_ID
ca-file=/etc/kubernetes/ca-bundle.crt
[BlockStorage]
bs-version=v2
EOF
