
# ------------------------------------------------------------------------------
# APPLY MANIFESTS
# ------------------------------------------------------------------------------
echo -e "${GREEN} Applying namespaces..."
kubectl apply -R -f ../conf/gitlab-test/namespaces/

sleep 5

kubectl apply -f ../conf/gitlab-test/deployment.yaml
kubectl apply -f ../conf/gitlab-test/service.yaml
kubectl apply -f ../conf/gitlab-test/ingress.yaml

echo -e "${GREEN} App available at http://localhost:8888"

# ------------------------------------------------------------------------------
# INSTALL ARGOCD
# ------------------------------------------------------------------------------
echo -e "${GREEN} Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting 20s for ArgoCD..."
sleep 40

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

# ------------------------------------------------------------------------------
# ARGOCD LOGIN
# ------------------------------------------------------------------------------
kubectl port-forward svc/argocd-server -n argocd 8080:443 >> /dev/null 1>&2
sleep 5

argocd login localhost:8080 \
  --username admin \
  --password "$ARGOCD_PASSWORD" \
  --insecure

# ------------------------------------------------------------------------------
# REGISTER YOUR GITLAB REPO
# ------------------------------------------------------------------------------
argocd repo add "http://gitlab-service.gitlab.svc.cluster.local/root/gitlab-test-repo.git" \
  --username root \
  --password "$GITLAB_PASSWORD" \
  --insecure

# ------------------------------------------------------------------------------
# CREATE APP
# ------------------------------------------------------------------------------
argocd app create myapp \
  --repo "http://gitlab-service.gitlab.svc.cluster.local/root/gitlab-test-repo.git" \
  --path p3 \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev

argocd app sync myapp


