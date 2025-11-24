#!/bin/bash
# install gitlab and run it
sudo docker run --detach \
  --hostname gitlab.example.com \
  --publish 4437:443 --publish 8081:80 --publish 2222:22 \
  --name gitlab \
  --restart always \
  --volume /srv/gitlab/config:/etc/gitlab \
  --volume /srv/gitlab/logs:/var/log/gitlab \
  --volume /srv/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ee:latest

