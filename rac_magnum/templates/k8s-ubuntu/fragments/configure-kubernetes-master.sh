#!/bin/bash

. /etc/default/heat-params

export DEBIAN_FRONTEND=noninteractive

echo "configuring kubernetes (master)"

#install k8s Ubuntu
sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -qq
sudo apt-get install -y kubectl=1.17.0-00 kubelet=1.17.0-00 kubeadm=1.17.0-00 kubernetes-cni=0.7.5-00

kubeadm config images pull

# Set sans
if [[ -z "${KUBE_NODE_IP}" ]]; then
    KUBE_NODE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
fi

sans="${KUBE_NODE_IP}"
_sans="\"${KUBE_NODE_IP}\""

if [[ -z "${KUBE_NODE_PUBLIC_IP}" ]]; then
    KUBE_NODE_PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
fi

if [[ -n "${KUBE_NODE_PUBLIC_IP}" ]]; then
  sans="${sans},${KUBE_NODE_PUBLIC_IP}"
  _sans="${_sans},\"${KUBE_NODE_PUBLIC_IP}\""
fi

if [ "${KUBE_NODE_PUBLIC_IP}" != "${KUBE_API_PUBLIC_ADDRESS}" ] \
        && [ -n "${KUBE_API_PUBLIC_ADDRESS}" ]; then
    sans="${sans},${KUBE_API_PUBLIC_ADDRESS}"
    _sans="${_sans},\"${KUBE_API_PUBLIC_ADDRESS}\""
fi
if [ "${KUBE_NODE_IP}" != "${KUBE_API_PRIVATE_ADDRESS}" ] \
        && [ -n "${KUBE_API_PRIVATE_ADDRESS}" ]; then
    sans="${sans},${KUBE_API_PRIVATE_ADDRESS}"
    _sans="${_sans},\"${KUBE_API_PRIVATE_ADDRESS}\""
fi

# JT
if [[ -n "${KUBE_NODE_IPV6}" ]]; then
  sans="${sans},${KUBE_NODE_IPV6}"
  _sans="${_sans},\"${KUBE_NODE_IPV6}\""
fi

MASTER_HOSTNAME=${MASTER_HOSTNAME:-}
if [[ -n "${MASTER_HOSTNAME}" ]]; then
    sans="${sans},${MASTER_HOSTNAME}"
    _sans="${_sans},\"${MASTER_HOSTNAME}\""
fi

sans="${sans},127.0.0.1"
_sans="${_sans},\"127.0.0.1\""

sans="${sans},kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster.local"
_sans="${_sans},\"kubernetes\",\"kubernetes.default\",\"kubernetes.default.svc\",\"kubernetes.default.svc.cluster.local\""

echo $sans
echo $_sans

# Create kubelet defaults file
cat > /etc/default/kubelet <<EOF
KUBELET_EXTRA_ARGS="--cloud-provider=external"
EOF

# Create a kubeadm manifest
cat > /etc/kubernetes/kubeadm.conf <<EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
nodeRegistration:
  kubeletExtraArgs:
    cloud-provider: "external"
localAPIEndpoint:
  advertiseAddress: ${KUBE_API_PRIVATE_ADDRESS}
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.17.0
networking:
  podSubnet: 10.244.0.0/16
controllerManager:
  extraVolumes:
  - name: "cloud-config"
    hostPath: "/etc/kubernetes/cloud-config"
    mountPath: "/etc/kubernetes/cloud-config"
    readOnly: true
    pathType: FileOrCreate
apiServer:
  certSANs: [${_sans}]
EOF

#result=$(kubeadm init \
# --pod-network-cidr 10.244.0.0/16 \
# --apiserver-advertise-address ${KUBE_API_PRIVATE_ADDRESS} \
# --apiserver-cert-extra-sans "$sans")

result=$(kubeadm init --config /etc/kubernetes/kubeadm.conf)

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

# https://github.com/kubernetes/cloud-provider-openstack/blob/a48fb75328b4956707f80e9743ae2a85f48bb455/docs/using-controller-manager-with-kubeadm.md
cp /etc/kubernetes/cloud-config cloud.conf
kubectl create secret generic -n kube-system cloud-config --from-file=cloud.conf
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/cluster/addons/rbac/cloud-controller-manager-roles.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/cluster/addons/rbac/cloud-controller-manager-role-bindings.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/controller-manager/openstack-cloud-controller-manager-ds.yaml

git clone https://github.com/kubernetes/cloud-provider-openstack
cd cloud-provider-openstack/manifests
rm cinder-csi-plugin/csi-secret-cinderplugin.yaml
kubectl apply -f cinder-csi-plugin
cd ../..
rm -rf cloud-provider-openstack
