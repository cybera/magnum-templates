#!/bin/bash

. /etc/default/heat-params

echo "configuring kubernetes (master)"

# Install k8s Ubuntu
sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -qq
sudo apt-get install -y kubectl=${KUBE_TAG} kubelet=${KUBE_TAG} kubeadm=${KUBE_TAG} kubernetes-cni

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

cat > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf <<EOF
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--cloud-provider=external --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use
# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.
EnvironmentFile=-/etc/default/kubelet
ExecStart=
ExecStart=/usr/bin/kubelet \$KUBELET_KUBECONFIG_ARGS \$KUBELET_CONFIG_ARGS \$KUBELET_KUBEADM_ARGS \$KUBELET_EXTRA_ARGS
EOF

cat > /etc/kubernetes/kubeadm.conf <<EOF
apiVersion: kubeadm.k8s.io/v1alpha3
kind: InitConfiguration
apiEndpoint:
  advertiseAddress: ${KUBE_API_PRIVATE_ADDRESS}
---
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1alpha3
apiServerExtraArgs:
  enable-admission-plugins: NodeRestriction,Initializers
  runtime-config: admissionregistration.k8s.io/v1alpha1
  authorization-mode: "Node,RBAC"
certificatesDir: /etc/kubernetes/pki
controllerManagerExtraArgs:
  external-cloud-volume-plugin: openstack
apiServerCertSANs: [${sans}]
networking:
  podSubnet: 10.244.0.0/16
EOF

cat > /etc/kubernetes/cloud-config <<EOF
[Global]
region=$REGION_NAME
auth-url=$AUTH_URL
user-id=$TRUSTEE_USER_ID
password=$TRUSTEE_PASSWORD
trust-id=$TRUST_ID
[BlockStorage]
bs-version=v3
EOF

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

# Set up networking
kubectl apply -f \
  https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml \
  --kubeconfig=/etc/kubernetes/admin.conf

# Enable Cinder
cat /etc/kubernetes/manifests/kube-controller-manager.yaml | perl -pe 's!    volumeMounts:!    volumeMounts:\n    - mountPath: /etc/kubernetes/cloud-config\n      name: cloud-config\n      readOnly: true!' | \
perl -pe 's!  volumes:!  volumes:\n  - name: cloud-config\n    hostPath:\n      path: /etc/kubernetes/cloud-config\n      type: FileOrCreate!' > /tmp/kube-controller-manager.yaml
mv /tmp/kube-controller-manager.yaml /etc/kubernetes/manifests/kube-controller-manager.yaml

kubectl create secret -n kube-system generic cloud-config --from-literal=cloud.conf="$(cat /etc/kubernetes/cloud-config)" --dry-run -o yaml > /tmp/cloud-config-secret.yaml
kubectl -f /tmp/cloud-config-secret.yaml apply
rm /tmp/cloud-config-secret.yaml

sleep 10

cat <<EOF | kubectl apply -f -
kind: InitializerConfiguration
apiVersion: admissionregistration.k8s.io/v1alpha1
metadata:
  name: pvlabel.kubernetes.io
initializers:
  - name: pvlabel.kubernetes.io
    rules:
    - apiGroups:
      - ""
      apiVersions:
      - "*"
      resources:
      - persistentvolumes
EOF

kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/cluster/addons/rbac/cloud-controller-manager-roles.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/cluster/addons/rbac/cloud-controller-manager-role-bindings.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/controller-manager/openstack-cloud-controller-manager-ds.yaml
