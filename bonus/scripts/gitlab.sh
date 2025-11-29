#!/bin/bash

set -e
sudo apt-get update -y

sudo apt-get install -y ca-certificates curl gnupg lsb-release

# ------------------------------------------------------------------------------
# INSTALL KUBECTL
# ------------------------------------------------------------------------------

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl


echo "==== Checking Docker installation ===="

# ----------------------------------------------------------------------
# INSTALL DOCKER ONLY IF NOT INSTALLED
# ----------------------------------------------------------------------
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



# ----------------------------------------------------------------------
# INSTALL K3D
# ----------------------------------------------------------------------

curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

sleep 5
# ----------------------------------------------------------------------
# CREATE CLUSTER ONLY IF NOT EXISTS
# ----------------------------------------------------------------------
    k3d cluster create k3dcluster \
        -p "8888:80@loadbalancer" \
        --agents 1
# if ! k3d cluster list | grep -q "k3dcluster"; then
#     echo "==== Creating k3d cluster ===="

# else
#     echo "Cluster 'k3dcluster' already exists — skipping creation."
# fi


# ----------------------------------------------------------------------
# APPLY KUBERNETES MANIFESTS
# ----------------------------------------------------------------------
echo "Waiting 10s for cluster to stabilize..."
sleep 10

kubectl apply -f ../conf/namespace.yaml
kubectl apply -f ../conf/deployment.yaml
kubectl apply -f ../conf/service.yaml
kubectl apply -f ../conf/ingress.yaml

sleep 60


kubectl port-forward -n gitlab svc/gitlab-service 30000:80

echo "==== DONE ===="
# n3aass wahd 3 min rah hadxi t9iiiiil 
sleep 60

# curl -H "Content-Type: application/json" \
#      -H "PRIVATE-TOKEN: <your-private-token>" \
#      -X POST "http://localhost:30000/api/v4/projects" \
#      -d '{"name":"gitlab-test-repo","visibility":"public"}'
