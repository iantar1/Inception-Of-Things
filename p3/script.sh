#!/bin/bash
GREEN='\033[0;32m'

echo -e "${GREEN} Updating system packages..."
sudo apt-get update -y

sudo apt-get install -y ca-certificates curl gnupg lsb-release

# ------------------------------------------------------------------------------
# INSTALL KUBECTL
# ------------------------------------------------------------------------------
echo -e "${GREEN} Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Let kubectl run without sudo
mkdir -p ~/.kube
sudo chown -R $USER:$USER ~/.kube

# ------------------------------------------------------------------------------
# INSTALL DOCKER
# ------------------------------------------------------------------------------
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)


# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl start docker

# ------------------------------------------------------------------------------
# INSTALL K3D
# ------------------------------------------------------------------------------
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# ------------------------------------------------------------------------------
# CREATE CLUSTER
# ------------------------------------------------------------------------------
echo -e "${GREEN} Creating k3d cluster..."
k3d cluster create k3dcluster \
  -p "8888:80@loadbalancer" \
  --agents 1

echo -e "${GREEN} Waiting 10s for cluster..."
sleep 10

# COPY KUBECONFIG FOR CURRENT USER
mkdir -p ~/.kube
k3d kubeconfig get k3dcluster > ~/.kube/config
chmod 600 ~/.kube/config

# Verify kubectl connection
echo -e "${GREEN} Testing kubectl..."
kubectl get nodes

# ------------------------------------------------------------------------------
# APPLY MANIFESTS
# ------------------------------------------------------------------------------
echo -e "${GREEN} Applying namespaces..."
kubectl apply -R -f namespaces/

sleep 5

kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml

echo -e "${GREEN} App available at http://localhost:8888"

# ------------------------------------------------------------------------------
# INSTALL ARGOCD
# ------------------------------------------------------------------------------
echo -e "${GREEN} Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting 20s for ArgoCD..."
sleep 20

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

# ------------------------------------------------------------------------------
# ARGOCD LOGIN
# ------------------------------------------------------------------------------
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
sleep 5

argocd login localhost:8080 \
  --username admin \
  --password "$ARGOCD_PASSWORD" \
  --insecure

# ------------------------------------------------------------------------------
# REGISTER YOUR GITHUB REPO
# ------------------------------------------------------------------------------
argocd repo add "https://github.com/iantar1/Inception-Of-Things.git" \
  --username root \
  --password "glpat-OMo5zPZIIqqD7Y9pPxk-BW86MQp1OjEH.01.0w1wb439s" \
  --insecure

# ------------------------------------------------------------------------------
# CREATE APP
# ------------------------------------------------------------------------------
argocd app create myapp \
  --repo "https://github.com/iantar1/Inception-Of-Things.git" \
  --path p3 \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev

argocd app sync myapp
