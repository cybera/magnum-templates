#!/bin/bash -x

. /etc/default/heat-params

export DEBIAN_FRONTEND=noninteractive

#install k8s Ubuntu
sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -qq
sudo apt-get install -y kubectl kubelet kubeadm kubernetes-cni

echo $JOIN_COMMAND

eval $JOIN_COMMAND
