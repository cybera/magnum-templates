#!/bin/bash

. /etc/default/heat-params

export DEBIAN_FRONTEND=noninteractive

echo "configuring kubernetes (master)"

#install k8s Ubuntu
sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -qq
sudo apt-get install -y kubectl kubelet kubeadm kubernetes-cni

kubeadm config images pull

# Set sans
if [[ -z "${KUBE_NODE_IP}" ]]; then
    KUBE_NODE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
fi

sans="${KUBE_NODE_IP}"

if [[ -z "${KUBE_NODE_PUBLIC_IP}" ]]; then
    KUBE_NODE_PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
fi

if [[ -n "${KUBE_NODE_PUBLIC_IP}" ]]; then
  sans="${sans},${KUBE_NODE_PUBLIC_IP}"
fi

if [ "${KUBE_NODE_PUBLIC_IP}" != "${KUBE_API_PUBLIC_ADDRESS}" ] \
        && [ -n "${KUBE_API_PUBLIC_ADDRESS}" ]; then
    sans="${sans},${KUBE_API_PUBLIC_ADDRESS}"
fi
if [ "${KUBE_NODE_IP}" != "${KUBE_API_PRIVATE_ADDRESS}" ] \
        && [ -n "${KUBE_API_PRIVATE_ADDRESS}" ]; then
    sans="${sans},${KUBE_API_PRIVATE_ADDRESS}"
fi

# JT
if [[ -n "${KUBE_NODE_IPV6}" ]]; then
  sans="${sans},${KUBE_NODE_IPV6}"
fi

MASTER_HOSTNAME=${MASTER_HOSTNAME:-}
if [[ -n "${MASTER_HOSTNAME}" ]]; then
    sans="${sans},${MASTER_HOSTNAME}"
fi

sans="${sans},127.0.0.1"

sans="${sans},kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster.local"

echo $sans

result=$(kubeadm init \
 --pod-network-cidr 10.244.0.0/16 \
 --apiserver-advertise-address ${KUBE_API_PRIVATE_ADDRESS} \
 --apiserver-cert-extra-sans "$sans")

echo $result

# Enable unsecured interface on localhost
sed -i '/insecure-port=0/a \    - --insecure-bind-address=0.0.0.0' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i 's/insecure-port=0/insecure-port=8080/' /etc/kubernetes/manifests/kube-apiserver.yaml

api_id=$(docker ps -qf name=k8s_kube-apiserver*)
docker stop $api_id && docker rm $api_id

echo "Waiting for Kubernetes API..."
until curl --silent "http://127.0.0.1:8080/version"
do
  sleep 5
done
