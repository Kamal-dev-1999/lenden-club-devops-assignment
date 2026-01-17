#!/bin/bash
set -e

# Update system packages
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y \
    curl \
    wget \
    git \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Add Docker GPG key and repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Start Docker
systemctl start docker
systemctl enable docker

# Download Docker Compose standalone (if not using plugin)
curl -L ${docker_compose_url} -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "Docker and Docker Compose installation complete"
