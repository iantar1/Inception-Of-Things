#!/bin/bash

set -e
sudo apt-get update -y

sudo apt-get install -y ca-certificates curl gnupg lsb-release

# ------------------------------------------------------------------------------
# INSTALL KUBECTL BEFORE K3D
# ------------------------------------------------------------------------------
echo -e "${GREEN} Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl


echo "==== Checking Docker installation ===="

# ----------------------------------------------------------------------
# INSTALL DOCKER ONLY IF NOT INSTALLED
# ----------------------------------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
    echo "Docker not found. Installing Docker..."

    sudo apt update -y
    sudo apt install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    sudo mkdir -p /etc/apt/keyrings

    # Add Docker GPG key only if missing
    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
            sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    fi

    # Add Docker repo only if missing
    if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
        echo \
          "deb [arch=$(dpkg --print-architecture) \
          signed-by=/etc/apt/keyrings/docker.gpg] \
          https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    fi

    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io

    sudo systemctl enable docker
    sudo systemctl restart docker

    echo "==== Docker Installed ===="

else
    echo "Docker already installed — skipping installation."
fi


# ----------------------------------------------------------------------
# INSTALL K3D IF NOT INSTALLED
# ----------------------------------------------------------------------
if ! command -v k3d >/dev/null 2>&1; then
    echo "==== Installing k3d ===="
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
    echo "k3d already installed — skipping."
fi


# ----------------------------------------------------------------------
# CREATE CLUSTER ONLY IF NOT EXISTS
# ----------------------------------------------------------------------
if ! k3d cluster list | grep -q "k3dcluster"; then
    echo "==== Creating k3d cluster ===="

    k3d cluster create k3dcluster \
        -p "8888:80@loadbalancer" \
        --agents 1

else
    echo "Cluster 'k3dcluster' already exists — skipping creation."
fi


# ----------------------------------------------------------------------
# APPLY KUBERNETES MANIFESTS
# ----------------------------------------------------------------------
echo "Waiting 10s for cluster to stabilize..."
sleep 10

kubectl apply -f ../conf/namespace.yaml
kubectl apply -f ../conf/deployment.yaml
kubectl apply -f ../conf/service.yaml
kubectl apply -f ../conf/ingress.yaml

sleep 20


kubectl port-forward -n gitlab svc/gitlab-service 30000:80

echo "==== DONE ===="
# n3aass wahd 3 min rah hadxi t9iiiiil 
sleep 60

# curl -H "Content-Type: application/json" \
#      -H "PRIVATE-TOKEN: <your-private-token>" \
#      -X POST "http://localhost:30000/api/v4/projects" \
#      -d '{"name":"gitlab-test-repo","visibility":"public"}'
