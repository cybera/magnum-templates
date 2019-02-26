#!/bin/bash

. /etc/default/heat-params

kubectl apply -f \
 https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml \
 --kubeconfig=/etc/kubernetes/admin.conf
