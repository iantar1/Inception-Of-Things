#!/bin/bash
set -e

# --------------------------------------------------------
# 0. PREREQUISITES
# --------------------------------------------------------

echo "[1/9] Updating system..."
sudo apt update -y && sudo apt upgrade -y

# --------------------------------------------------------
# 1. INSTALL DOCKER
# --------------------------------------------------------
echo "[2/9] Installing Docker..."

sudo apt install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker $USER 2>/dev/null || true


# --------------------------------------------------------
# 2. INSTALL K3s
# --------------------------------------------------------

echo "[3/9] Installing K3s..."

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "Waiting for K3s to be ready..."
sleep 15


# --------------------------------------------------------
# 3. INSTALL HELM
# --------------------------------------------------------

echo "[4/9] Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash


# --------------------------------------------------------
# 4. CREATE NAMESPACE
# --------------------------------------------------------

echo "[5/9] Creating gitlab namespace..."

kubectl create namespace gitlab || true


# --------------------------------------------------------
# 5. ADD HELM REPOS
# --------------------------------------------------------

echo "[6/9] Adding GitLab Helm repo..."

helm repo add gitlab https://charts.gitlab.io/ || true
helm repo update


# --------------------------------------------------------
# 6. CREATE GITALY TOKEN SECRET
# --------------------------------------------------------

echo "[7/9] Creating Gitaly secret..."

kubectl -n gitlab delete secret gitaly-secret 2>/dev/null || true
kubectl -n gitlab create secret generic gitaly-secret \
  --from-literal=token="same-token-everywhere"


# --------------------------------------------------------
# 7. GENERATE values.yaml
# --------------------------------------------------------

echo "[8/9] Generating values.yaml..."


# --------------------------------------------------------
# 8. CREATE INITIAL ROOT PASSWORD SECRET
# --------------------------------------------------------

echo "[9/9] Creating GitLab root password secret..."

kubectl -n gitlab delete secret gitlab-initial-root-password 2>/dev/null || true

kubectl -n gitlab create secret generic gitlab-initial-root-password \
  --from-literal=password="Passw0rd123"


# --------------------------------------------------------
# 9. INSTALL GITLAB
# --------------------------------------------------------

echo "Installing GitLab... this takes several minutes..."

helm upgrade --install gitlab gitlab/gitlab \
  -n gitlab \
  -f ../conf/values.yaml \
  --timeout 40m

echo ""
echo "--------------------------------------------------------"
echo "🎉 Installation complete!"
echo "GitLab URL:     http://gitlab.gitlab.local"
echo "Root password:  Passw0rd123"
echo ""
echo "IMPORTANT:"
echo "Add this to your /etc/hosts:"
echo "   127.0.0.1   gitlab.gitlab.local"
echo ""
echo "Then open in browser:  http://gitlab.gitlab.local"
echo "--------------------------------------------------------"
