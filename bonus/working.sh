sudo helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab --create-namespace \
  --timeout 600s \
  --set global.hosts.domain=localhost \
  --set global.hosts.externalIP=127.0.0.1 \
  --set certmanager-issuer.email="you@example.com" \
  --set global.gitaly.enabled=true \
  --set global.gitaly.replicaCount=1 \
  --set global.minio.enabled=true \
  --set global.postgresql.install=true \
  --set global.redis.install=true \
  --set global.registry.enabled=false \
  --set global.prometheus.install=false



sudo docker run --detach \
  --hostname gitlab.example.com \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume /srv/gitlab/config:/etc/gitlab \
  --volume /srv/gitlab/logs:/var/log/gitlab \
  --volume /srv/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ee:latest
