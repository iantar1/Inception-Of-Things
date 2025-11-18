#!/bin/bash
GREEN ='\033[0;32m'

echo -e "${GREEN} Updating system packages..."
sudo apt-get update -y

sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

# install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Create k3d cluster
sudo k3d cluster create k3dcluster \
  -p "8888:80@loadbalancer" \
  --agents 1

echo "${GREEN}⏳ Waiting for the cluster to initialize..."
sleep 15


echo "${GREEN}🔑 Configuring kubectl context for k3dcluster..."
sudo kubectl config use-context k3d-k3dcluster

echo "${GREEN} 📦 Applying Kubernetes manifests..."

sudo kubectl apply -R -f namespaces/
echo "${GREEN}⏳ Waiting for namespaces to be created..."
sleep 10


sudo apply -f deployments.yaml
sudo apply -f service.yaml
sudo apply -f ingress.yaml



echo "${GREEN}✅ All resources applied successfully!"
echo "${GREEN}🌍 Access your app at: http://localhost:8888"

# argocd installation
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Install Argo CD CLI
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd


# Expose Argo CD UI
sudo kubectl port-forward svc/argocd-server -n argocd 8080:443

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo "🔑 Logging into Argo CD..."
argocd login localhost:8080 \
  --username admin \
  --password "$ARGOCD_PASSWORD" \
  --insecure

argocd app create myapp \
  --repo https://github.com/iantar1/Inception-Of-Things.git \
  --path p3 \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev


argocd app sync myapp