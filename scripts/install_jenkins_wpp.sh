#!/bin/bash

# this script is only tested on ubuntu focal 20.04 (LTS)

# install docker
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# run jenkins
sudo docker network create jenkins
sudo mkdir -p /var/jenkins_home
chown -R 1000:1000 /var/jenkins_home/
sudo mkdir -p /var/jenkins-docker-certs
chown -R 1000:1000 /var/jenkins-docker-certs

docker run \
  --name jenkins-docker \
  --detach \
  --privileged \
  --network jenkins \
  --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume /var/jenkins-docker-certs:/certs/client \
  --volume /var/jenkins_home:/var/jenkins_home \
  --publish 2376:2376 \
  docker:dind \
  --storage-driver overlay2
  

cd /home/ubuntu/jenkins-course/scripts/
 

docker build -t myjenkins-blueocean:1.1 .

docker run \
  --name jenkins \
  --rm \
  --detach \
  --network jenkins \
  --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client \
  --env DOCKER_TLS_VERIFY=1 \
  --publish 8080:8080 \
  --publish 50000:50000 \
  --volume /var/jenkins_home:/var/jenkins_home \
  --volume /var/jenkins-docker-certs:/certs/client:ro \
  myjenkins-blueocean:1.1 


# show endpoint
echo 'Jenkins installed'
echo 'You should now be able to access jenkins at: http://'$(curl -s ifconfig.co)':8080'
