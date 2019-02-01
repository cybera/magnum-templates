#!/bin/bash

. /etc/default/heat-params

echo "configuring kubernetes (master)"

#install k8s Ubuntu
sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -qq
sudo apt-get install -y kubectl kubelet kubeadm kubernetes-cni
getent passwd kube >/dev/null
if [ $? != 0 ]; then
  useradd -c "Kubernetes service user" -s /sbin/nologin --system kube
fi

kubeadm config images pull

swapoff -a

result=$(kubeadm init \
 --pod-network-cidr ${PODS_NETWORK_CIDR} \
 --service-cidr ${PORTAL_NETWORK_CIDR} \
 --service-dns-domain "${DNS_CLUSTER_DOMAIN}" \
 --apiserver-advertise-address ${KUBE_API_PRIVATE_ADDRESS})

#echo $result

# Enable unsecured interface on localhost
sed -i '/insecure-port=0/a \    - --insecure-bind-address=0.0.0.0' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i 's/insecure-port=0/insecure-port=8080/' /etc/kubernetes/manifests/kube-apiserver.yaml

api_id=$(docker ps -qf name=k8s_kube-apiserver*)
docker stop $api_id && docker rm $api_id
