sudo k3d cluster create mycluster \
  -p "8888:80@loadbalancer" \
  --agents 1
