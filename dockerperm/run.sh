#!/bin/bash
# "permission denied while trying to connect to the Docker daemon socket": who gets it, and which fix survives.
set +e
docker version --format 'Docker {{.Server.Version}}'; lsb_release -ds; ls -l /var/run/docker.sock
sudo useradd -m dev
echo "== 1. user not in docker group"; sudo -u dev docker ps 2>&1 | head -2
echo "-- id:"; sudo -u dev id
echo "== 2. usermod while a shell is already open"
sudo -u dev bash -c 'sleep 6; echo "old shell groups: $(id -Gn)"; docker ps 2>&1 | head -1' &
sleep 2; sudo usermod -aG docker dev; wait
echo "-- a new login (sudo -u starts fresh):"; sudo -u dev bash -c 'id -Gn; docker ps --format x >/dev/null && echo "docker ps OK"'
echo "-- newgrp-style (sg) from an old shell:"
sudo gpasswd -d dev docker >/dev/null
sudo -u dev bash -c 'sleep 6; sg docker -c "docker ps --format x >/dev/null && echo sg docker ps OK" 2>&1 | head -1; newgrp docker <<<"docker ps --format x >/dev/null && echo newgrp docker ps OK" 2>&1 | head -1' &
sleep 2; sudo usermod -aG docker dev; wait
sudo gpasswd -d dev docker >/dev/null
echo "== 3. chmod 666 the socket"
sudo chmod 666 /var/run/docker.sock; ls -l /var/run/docker.sock; sudo -u dev docker ps --format x >/dev/null && echo "after chmod 666: docker ps OK"
sudo systemctl restart docker; sleep 5; ls -l /var/run/docker.sock; sudo -u dev docker ps 2>&1 | head -1
echo "-- after a full socket restart:"; sudo systemctl restart docker.socket docker; sleep 5; ls -l /var/run/docker.sock; sudo -u dev docker ps 2>&1 | head -1
echo "== 4. sudo docker"; sudo -u dev sudo -n docker ps --format x >/dev/null 2>&1 && echo "sudo docker OK" || echo "sudo docker: needs password / not allowed for dev"
echo "== 5. daemon stopped"
sudo usermod -aG docker dev
sudo systemctl stop docker.socket docker; sleep 2; sudo -u dev docker ps 2>&1 | head -2; docker ps 2>&1 | head -1
sudo systemctl start docker; sleep 4
echo "== 6. DOCKER_HOST pointing elsewhere"; sudo -u dev env DOCKER_HOST=unix:///tmp/nope.sock docker ps 2>&1 | head -1
sudo -u dev env DOCKER_HOST=tcp://localhost:2375 docker ps 2>&1 | head -1
echo "== 7. context"; sudo -u dev docker context ls 2>&1 | head -3
